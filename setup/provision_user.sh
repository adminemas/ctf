#!/bin/bash
# /var/ctf/setup/provision_user.sh <username> [password]
# Yangi talaba uchun hisob, uy papkasi va 10 ta quiz muhitini tayyorlaydi.

set -e

if [ -z "$1" ]; then
    echo "Foydalanish: $0 <username> [password]"
    exit 1
fi

USERNAME=$1
PASSWORD=$2

if [ -z "$PASSWORD" ] && [ ! -t 0 ]; then
    read -r PASSWORD || true
fi

HOME_DIR="/home/$USERNAME"

# 0) Username sintaksisi va tizim hisoblarini tekshirish
if [[ ! "$USERNAME" =~ ^[a-z][a-z0-9_]{1,31}$ ]]; then
    echo "❌ Xato: Yaroqsiz username ('$USERNAME'). Faqat kichik lotin harflari, raqamlar va pastki chiziq."
    exit 1
fi

RESERVED=("root" "daemon" "bin" "sys" "sync" "games" "man" "lp" "mail" "news" "uucp" \
          "proxy" "www-data" "backup" "list" "irc" "gnats" "nobody" "systemd-network" \
          "systemd-resolve" "systemd-timesync" "messagebus" "sshd" "ubuntu" "debian" "admin" "user" "sudo")
for r in "${RESERVED[@]}"; do
    if [ "$USERNAME" = "$r" ]; then
        echo "❌ Xato: '$USERNAME' — himoyalangan tizim foydalanuvchisi!"
        exit 1
    fi
done

# 1) Linux user yaratish
if id "$USERNAME" &>/dev/null; then
    if ! id -nG "$USERNAME" 2>/dev/null | grep -qw "ctfstudents"; then
        echo "❌ Xato: '$USERNAME' mavjud tizim foydalanuvchisi va CTF talabasi emas!"
        exit 1
    fi
    echo "[i] Talaba foydalanuvchisi mavjud: $USERNAME"
else
    useradd -m -s /bin/bash "$USERNAME"
    echo "[+] Linux foydalanuvchisi yaratildi: $USERNAME"
fi

# Talabalar bir-birining papkalariga kira olmasligi uchun
chmod 700 "$HOME_DIR"

# Parol o'rnatish
if [ -n "$PASSWORD" ]; then
    echo "$USERNAME:$PASSWORD" | chpasswd
    echo "[+] Parol o'rnatildi: $USERNAME"
fi

# CTF guruhiga qo'shish
getent group ctfstudents >/dev/null || groupadd ctfstudents
usermod -aG ctfstudents "$USERNAME"

# Baza yozuvi
printf "INSERT OR IGNORE INTO progress (username, current_stage) VALUES ('%s', 1);\n" "$USERNAME" \
    | sqlite3 -cmd ".timeout 5000" /var/ctf/ctf.db

# 2) 10 ta quiz materiallari va yashiringan flaglarni generatsiya qilish
bash /var/ctf/setup/generate_seed.sh "$USERNAME"

echo "[+] $USERNAME uchun CTF muhiti to'liq tayyorlandi!"
echo "    Talaba kirishi: ssh $USERNAME@<server-ip>"
