#!/bin/bash
# /var/ctf/setup/add_students.sh
# Talabalarni ommaviy qo'shish va parollarni jadvalga saqlash skripti.
#
# Foydalanish:
#   sudo bash add_students.sh --range talaba 1 30
#   sudo bash add_students.sh --range talaba 1 30 --password "CtfPass2026!"
#   sudo bash add_students.sh talabalar_royxati.txt

set -e

if [ "$EUID" -ne 0 ]; then
    echo "❌ sudo bilan ishga tushiring: sudo bash $0 ..."
    exit 1
fi

MODE=""
PREFIX=""
START_NUM=1
END_NUM=1
INPUT_FILE=""
FIXED_PASSWORD=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --range)
            MODE="range"
            PREFIX="$2"
            START_NUM="$3"
            END_NUM="$4"
            shift 4
            ;;
        --password)
            FIXED_PASSWORD="$2"
            shift 2
            ;;
        *)
            if [ -f "$1" ]; then
                MODE="file"
                INPUT_FILE="$1"
                shift
            else
                echo "❌ Noma'lum parametr: $1"
                exit 1
            fi
            ;;
    esac
done

if [ -z "$MODE" ]; then
    echo "Foydalanish:"
    echo "  sudo bash $0 --range <prefix> <boshlanish> <tugash> [--password <parol>]"
    echo "  sudo bash $0 <students.txt> [--password <parol>]"
    echo ""
    echo "Misollar:"
    echo "  sudo bash $0 --range talaba 1 20"
    echo "  sudo bash $0 --range talaba 1 20 --password 'Linux2026!'"
    echo "  sudo bash $0 talabalar.txt"
    exit 1
fi

STUDENTS_TXT="created_students.txt"
STUDENTS_CSV="created_students.csv"

echo "================================================="
echo "  LINUX CTF — OMMAVIY TALABA YARATISH"
echo "================================================="

mkdir -p "$(dirname "$STUDENTS_TXT")"
[ ! -f "$STUDENTS_CSV" ] && echo "username,password" > "$STUDENTS_CSV"

create_one() {
    local U="$1"
    local P="$2"
    if [ -z "$P" ]; then
        P=$(openssl rand -base64 9 | tr -dc 'a-zA-Z0-9' | head -c 8)
    fi

    echo -n "[$U] yaratilmoqda... "
    bash /var/ctf/setup/provision_user.sh "$U" "$P" >/dev/null 2>&1
    echo "tayyor! (Parol: $P)"

    printf "%-18s : %s\n" "$U" "$P" >> "$STUDENTS_TXT"
    echo "$U,$P" >> "$STUDENTS_CSV"
}

if [ "$MODE" = "range" ]; then
    echo "[i] $PREFIX$START_NUM dan $PREFIX$END_NUM gacha yaratilmoqda..."
    for ((i=START_NUM; i<=END_NUM; i++)); do
        USER_NAME="${PREFIX}${i}"
        create_one "$USER_NAME" "$FIXED_PASSWORD"
    done
elif [ "$MODE" = "file" ]; then
    echo "[i] Fayldan o'qilmoqda: $INPUT_FILE"
    while IFS= read -r line || [ -n "$line" ]; do
        line=$(echo "$line" | tr -d '\r' | xargs)
        [ -z "$line" ] && continue
        [[ "$line" =~ ^# ]] && continue
        create_one "$line" "$FIXED_PASSWORD"
    done < "$INPUT_FILE"
fi

echo ""
echo "✅ Barcha talabalar muvaffaqiyatli qo'shildi!"
echo "📄 Login va parollar saqlandi:"
echo "   - $STUDENTS_TXT"
echo "   - $STUDENTS_CSV"
