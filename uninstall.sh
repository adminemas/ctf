#!/bin/bash
# uninstall.sh — Linux Praktikum CTF loyihasini tozalash yoki o'chirish
# Foydalanish:
#   sudo bash uninstall.sh --students-only    # Faqat talabalar hisoblarini tozalash
#   sudo bash uninstall.sh --student <user>   # Bitta talabani o'chirish
#   sudo bash uninstall.sh --all              # Butun tizimni to'liq o'chirish

set -e

if [ "$EUID" -ne 0 ]; then
    echo "❌ sudo bilan ishga tushiring: sudo bash $0 ..."
    exit 1
fi

MODE="$1"
SINGLE_USER="$2"

if [[ "$MODE" != "--students-only" && "$MODE" != "--all" && "$MODE" != "--student" ]]; then
    echo "Foydalanish:"
    echo "  sudo bash $0 --students-only       # Barcha talabalarni tozalash (yangi guruh uchun)"
    echo "  sudo bash $0 --student <username>  # Bitta talabani o'chirish"
    echo "  sudo bash $0 --all                 # Butun CTF tizimini to'liq o'chirish"
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Zaxiralash
archive_ctf_data() {
    local DB_PATH="/var/ctf/ctf.db"
    if [ ! -f "$DB_PATH" ]; then
        return 0
    fi

    local TOTAL_USERS=$(sqlite3 -cmd ".timeout 5000" "$DB_PATH" "SELECT COUNT(*) FROM progress;" 2>/dev/null || echo 0)
    if [ -z "$TOTAL_USERS" ] || [ "$TOTAL_USERS" -eq 0 ]; then
        return 0
    fi

    local TIMESTAMP=$(date '+%Y-%m-%d_%H-%M-%S')
    local BACKUP_DIR="/var/ctf/backups/$TIMESTAMP"
    mkdir -p "$BACKUP_DIR" 2>/dev/null || true

    echo "📦 [Zaxira] Baza va natijalar arxivlanmoqda: $BACKUP_DIR"
    cp "$DB_PATH" "$BACKUP_DIR/ctf_backup.db" 2>/dev/null || true
    sqlite3 "$DB_PATH" ".dump" > "$BACKUP_DIR/dump.sql" 2>/dev/null || true
    echo "   ✅ Arxiv saqlandi: $BACKUP_DIR"
}

archive_ctf_data

delete_student() {
    local U="$1"
    if id "$U" &>/dev/null; then
        echo "   O'chirilmoqda: $U"
        # Jarayonlarni to'xtatish
        pkill -u "$U" 2>/dev/null || true
        # Crontabni tozalash
        crontab -r -u "$U" 2>/dev/null || true
        # Foydalanuvchi va uy katalogini o'chirish
        userdel -r -f "$U" 2>/dev/null || rm -rf "/home/$U"
    fi
}

if [ "$MODE" = "--student" ]; then
    if [ -z "$SINGLE_USER" ]; then
        echo "❌ Foydalanuvchi nomi ko'rsatilmadi: sudo bash $0 --student <username>"
        exit 1
    fi
    echo "[i] Talaba o'chirilmoqda: $SINGLE_USER"
    delete_student "$SINGLE_USER"
    sqlite3 -cmd ".timeout 5000" /var/ctf/ctf.db "DELETE FROM progress WHERE username='$SINGLE_USER';" 2>/dev/null || true
    sqlite3 -cmd ".timeout 5000" /var/ctf/ctf.db "DELETE FROM attempts WHERE username='$SINGLE_USER';" 2>/dev/null || true
    sqlite3 -cmd ".timeout 5000" /var/ctf/ctf.db "DELETE FROM answers WHERE username='$SINGLE_USER';" 2>/dev/null || true
    sqlite3 -cmd ".timeout 5000" /var/ctf/ctf.db "DELETE FROM solved_stages WHERE username='$SINGLE_USER';" 2>/dev/null || true
    sqlite3 -cmd ".timeout 5000" /var/ctf/ctf.db "DELETE FROM flags WHERE username='$SINGLE_USER';" 2>/dev/null || true
    echo "✅ $SINGLE_USER muvaffaqiyatli o'chirildi."
    exit 0
fi

if [ "$MODE" = "--students-only" ] || [ "$MODE" = "--all" ]; then
    echo "[i] CTF talabalari aniqlanmoqda..."
    if [ -f /var/ctf/ctf.db ]; then
        STUDENTS=$(sqlite3 -cmd ".timeout 5000" /var/ctf/ctf.db "SELECT username FROM progress;" 2>/dev/null || echo "")
        for U in $STUDENTS; do
            delete_student "$U"
        done
    fi

    # ctfstudents guruhidagi foydalanuvchilar
    MEMBERS=$(getent group ctfstudents | cut -d: -f4 | tr ',' ' ' 2>/dev/null || echo "")
    for U in $MEMBERS; do
        delete_student "$U"
    done

    # Bazani tozalash
    if [ -f /var/ctf/ctf.db ]; then
        sqlite3 -cmd ".timeout 5000" /var/ctf/ctf.db <<EOF
DELETE FROM progress;
DELETE FROM attempts;
DELETE FROM answers;
DELETE FROM solved_stages;
DELETE FROM flags;
DELETE FROM ssh_activity;
VACUUM;
EOF
    fi
    echo "✅ Barcha talabalar tozalandi."
fi

if [ "$MODE" = "--all" ]; then
    echo "[i] Butun CTF tizimi o'chirilmoqda..."
    # Web server va Bot to'xtatish
    python3 /var/ctf/admin/server.py stop 2>/dev/null || true
    systemctl stop ctf-bot 2>/dev/null || true
    systemctl disable ctf-bot 2>/dev/null || true
    rm -f /etc/systemd/system/ctf-bot.service
    systemctl daemon-reload 2>/dev/null || true

    # Buyruqlarni olib tashlash
    rm -f /usr/local/bin/check /usr/local/bin/status /usr/local/bin/ctf-admin /usr/local/bin/ctf-web /usr/local/bin/ctf-reset
    rm -f /etc/sudoers.d/ctf-general
    rm -f /etc/security/limits.d/ctfstudents.conf
    groupdel ctfstudents 2>/dev/null || true
    rm -rf /var/ctf

    echo "✅ CTF tizimi to'liq o'chirildi."
fi
