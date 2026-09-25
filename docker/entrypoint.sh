#!/bin/bash
# docker/entrypoint.sh — Railway / Docker yuklanish skripti

set -e

echo "=========================================================="
echo "🚀 Linux Praktikum CTF — Container ishga tushmoqda..."
echo "=========================================================="

mkdir -p /var/log/supervisor /var/run/sshd /var/ctf/backups /var/ctf/bot

# 1. SSH host kalitlarini generatsiya qilish (agar mavjud bo'lmasa)
ssh-keygen -A

# 2. CTF guruhini tekshirish
getent group ctfstudents >/dev/null || groupadd ctfstudents

# 3. Bazani tekshirish va yaratish
if [ ! -f /var/ctf/ctf.db ]; then
    echo "[i] Ma'lumotlar bazasi topilmadi. Yangi baza yaratilmoqda..."
    bash /var/ctf/setup/init_db.sh
fi

# 4. Telegram Bot konfiguratsiyasi (Env orqali yoki mavjud fayl)
if [ ! -f /var/ctf/bot/config.py ]; then
    TOKEN="${BOT_TOKEN:-YOUR_BOT_TOKEN_HERE}"
    ADMINS="${ADMIN_IDS:-[]}"
    cat > /var/ctf/bot/config.py <<EOF
BOT_TOKEN = "${TOKEN}"
SERVER_IP = "auto"
DB_PATH = "/var/ctf/ctf.db"
ADMIN_IDS = ${ADMINS}
EOF
fi

# 5. Talabalarni avtomatik qayta tiklash (Container restart/redeploy bo'lsa)
if [ -f /var/ctf/ctf.db ]; then
    echo "[i] Mavjud talabalar tekshirilmoqda..."
    STUDENTS=$(sqlite3 /var/ctf/ctf.db "SELECT DISTINCT username FROM progress UNION SELECT DISTINCT ssh_username FROM telegram_users WHERE ssh_username IS NOT NULL;" 2>/dev/null || true)
    for U in $STUDENTS; do
        if [ -n "$U" ] && ! id "$U" &>/dev/null; then
            echo "[+] Qayta tiklanmoqda: $U"
            useradd -m -s /bin/bash "$U" 2>/dev/null || true
            chmod 700 "/home/$U" 2>/dev/null || true
            usermod -aG ctfstudents "$U" 2>/dev/null || true
            
            # Parolni tiklash
            PASS=$(sqlite3 /var/ctf/ctf.db "SELECT ssh_password FROM telegram_users WHERE ssh_username='$U';" 2>/dev/null || true)
            if [ -n "$PASS" ]; then
                echo "$U:$PASS" | chpasswd
            fi
            
            # Quiz muhitini tiklash
            if [ ! -d "/home/$U/quiz1" ]; then
                bash /var/ctf/setup/generate_seed.sh "$U" 2>/dev/null || true
                CURR=$(sqlite3 /var/ctf/ctf.db "SELECT current_stage FROM progress WHERE username='$U';" 2>/dev/null || echo 1)
                for ((s=1; s<=CURR && s<=10; s++)); do
                    chmod 750 "/home/$U/quiz$s" 2>/dev/null || true
                    chown -R "$U:$U" "/home/$U/quiz$s" 2>/dev/null || true
                done
            fi
        fi
    done
fi

# 6. Sudoers va xavfsizlik
if [ -f /var/ctf/setup/sudoers_ctf_general ]; then
    cp /var/ctf/setup/sudoers_ctf_general /etc/sudoers.d/ctf-general
    chmod 440 /etc/sudoers.d/ctf-general
fi

echo "=========================================================="
echo "✅ Tizim tayyor! Supervisor orqali xizmatlar ishga tushirilmoqda..."
echo "=========================================================="

exec /usr/bin/supervisord -n -c /opt/ctf/docker/supervisord.conf
