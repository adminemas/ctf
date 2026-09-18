#!/bin/bash
# install.sh — Linux Praktikum CTF loyihasini o'rnatish
# Foydalanish: sudo bash install.sh

set -e

if [ "$EUID" -ne 0 ]; then
    echo "❌ Xato: Ushbu skriptni sudo bilan ishga tushiring: sudo bash install.sh"
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "╔══════════════════════════════════════════════════════════════════╗"
echo "║          🚩 LINUX PRAKTIKUM CTF — O'RNATISH BOSHLANDI            ║"
echo "╚══════════════════════════════════════════════════════════════════╝"

# [1/6] Kerakli paketlarni tekshirish va o'rnatish
echo "[1/6] Kerakli paketlar va xizmatlar tekshirilmoqda..."
MISSING=0
for cmd in sqlite3 openssl python3 git cron at column diff comm sed sort uniq cut; do
    if ! which "$cmd" &>/dev/null; then
        MISSING=1
        break
    fi
done

if [ "$MISSING" -eq 1 ]; then
    apt-get update -qq || true
    apt-get install -y sqlite3 openssl python3 git cron at bsdmainutils diffutils coreutils gawk sed >/dev/null 2>&1 || true
fi

# Xizmatlarni ishga tushirish (cron va atd)
systemctl enable --now cron 2>/dev/null || systemctl enable --now crond 2>/dev/null || true
systemctl enable --now atd 2>/dev/null || true

# [2/6] /var/ctf tuzilishi
echo "[2/6] /var/ctf kataloglari yaratilmoqda..."
mkdir -p /var/ctf/tasks /var/ctf/setup /var/ctf/admin /var/ctf/backups
cp "$SCRIPT_DIR"/tasks/*.sh /var/ctf/tasks/
cp "$SCRIPT_DIR"/setup/*.sh /var/ctf/setup/
cp "$SCRIPT_DIR"/admin/*.py /var/ctf/admin/

chmod 700 /var/ctf/tasks/*.sh /var/ctf/setup/*.sh
chmod 755 /var/ctf/admin/*.py
chown -R root:root /var/ctf

# [3/6] Baza va xavfsizlik kaliti
echo "[3/6] Ma'lumotlar bazasi va maxfiy kalit sozlanmoqda..."
bash /var/ctf/setup/init_db.sh

# [4/6] Tizim buyruqlari (/usr/local/bin)
echo "[4/6] Tizim buyruqlari /usr/local/bin ga o'rnatilmoqda..."
cp "$SCRIPT_DIR"/bin/check      /usr/local/bin/check
cp "$SCRIPT_DIR"/bin/status     /usr/local/bin/status
cp "$SCRIPT_DIR"/bin/ctf-admin  /usr/local/bin/ctf-admin
cp "$SCRIPT_DIR"/bin/ctf-web    /usr/local/bin/ctf-web
cp "$SCRIPT_DIR"/bin/ctf-reset  /usr/local/bin/ctf-reset

chmod 755 /usr/local/bin/check /usr/local/bin/status \
          /usr/local/bin/ctf-admin /usr/local/bin/ctf-web /usr/local/bin/ctf-reset
chown root:root /usr/local/bin/check /usr/local/bin/status \
                /usr/local/bin/ctf-admin /usr/local/bin/ctf-web /usr/local/bin/ctf-reset

# [5/6] Guruh, sudo qoidalari va xavfsizlik limitlari
echo "[5/6] Sudo qoidalari va xavfsizlik cheklovlari qo'yilmoqda..."
getent group ctfstudents >/dev/null || groupadd ctfstudents
cp "$SCRIPT_DIR"/setup/sudoers_ctf_general /etc/sudoers.d/ctf-general
chmod 440 /etc/sudoers.d/ctf-general
visudo -c -f /etc/sudoers.d/ctf-general

cat > /etc/security/limits.d/ctfstudents.conf <<'EOF'
# CTF talabalari uchun xavfsizlik va resurs chegaralari
@ctfstudents hard nproc 60
@ctfstudents soft nproc 40
@ctfstudents hard maxlogins 4
@ctfstudents soft fsize 102400
@ctfstudents hard fsize 204800
EOF
chmod 644 /etc/security/limits.d/ctfstudents.conf

# Web Dashboard admin hisobi
if [ ! -f /var/ctf/admin.cred ]; then
    ADMIN_PASS=$(openssl rand -hex 6)
    echo "admin:$ADMIN_PASS" > /var/ctf/admin.cred
    chmod 600 /var/ctf/admin.cred
    echo "   🔑 Web Dashboard: Login: admin | Parol: $ADMIN_PASS"
fi

# [6/6] Tugatish xabari
echo ""
echo "╔══════════════════════════════════════════════════════════════════╗"
echo "║             ✅ CTF TIZIMI MUVAFFAQIYATLI O'RNATILDI!            ║"
echo "╠══════════════════════════════════════════════════════════════════╣"
echo "║  📌 Talabalar qo'shish:                                          ║"
echo "║    sudo bash /var/ctf/setup/add_students.sh --range talaba 1 20  ║"
echo "║    yoki:                                                         ║"
echo "║    sudo bash /var/ctf/setup/provision_user.sh talaba1            ║"
echo "║                                                                  ║"
echo "║  🖥 Terminal Jonli Monitoring:  ctf-admin                         ║"
echo "║  🌐 Web Jonli Dashboard:        sudo ctf-web                     ║"
echo "║  🔄 Talabani nollash:           sudo ctf-reset <username>        ║"
echo "╚══════════════════════════════════════════════════════════════════╝"
echo ""
