#!/bin/bash
# /var/ctf/setup/generate_seed.sh <username>
# Har bir talaba uchun 10 ta quiz materiallari, yashiringan flaglar va README.txt larni tayyorlaydi.
# Har bir quiz uchun yashiringan individual flag generatsiya qilinadi.

set -e

if [ -z "$1" ]; then
    echo "Foydalanish: $0 <username>"
    exit 1
fi

USERNAME=$1
HOME_DIR="/home/$USERNAME"
DB="/var/ctf/ctf.db"
KEY_FILE="/var/ctf/secret.key"

if [ ! -f "$KEY_FILE" ]; then
    mkdir -p /var/ctf
    openssl rand -hex 32 > "$KEY_FILE"
    chmod 600 "$KEY_FILE"
fi
SECRET=$(cat "$KEY_FILE")

lock_dir() {
    chmod 000 "$1"
    chown root:root "$1"
}

# 10 ta bosqich uchun alohida salt va flag generatsiya qilish
gen_salt() {
    local stage=$1
    echo -n "${USERNAME}:${SECRET}:stage${stage}" | sha256sum | cut -c1-10
}

SALT1=$(gen_salt 1)
SALT2=$(gen_salt 2)
SALT3=$(gen_salt 3)
SALT4=$(gen_salt 4)
SALT5=$(gen_salt 5)
SALT6=$(gen_salt 6)
SALT7=$(gen_salt 7)
SALT8=$(gen_salt 8)
SALT9=$(gen_salt 9)
SALT10=$(gen_salt 10)

FLAG1="FLAG{quiz1_hidden_vault_${SALT1}}"
FLAG2="FLAG{quiz2_grep_cut_${SALT2}}"
FLAG3="FLAG{quiz3_sort_uniq_${SALT3}}"
FLAG4="FLAG{quiz4_diff_comm_${SALT4}}"
FLAG5="FLAG{quiz5_sed_column_${SALT5}}"
FLAG6="FLAG{quiz6_find_chmod_${SALT6}}"
FLAG7="FLAG{quiz7_git_history_${SALT7}}"
FLAG8="FLAG{quiz8_crontab_at_${SALT8}}"
FLAG9="FLAG{quiz9_dpkg_apt_${SALT9}}"
FLAG10="FLAG{quiz10_ninja_master_${SALT10}}"

# Bazaga flaglarni yozish
sqlite3 -cmd ".timeout 5000" "$DB" <<EOF
INSERT OR REPLACE INTO answers (username, stage, expected) VALUES ('$USERNAME', 1, '$FLAG1');
INSERT OR REPLACE INTO answers (username, stage, expected) VALUES ('$USERNAME', 2, '$FLAG2');
INSERT OR REPLACE INTO answers (username, stage, expected) VALUES ('$USERNAME', 3, '$FLAG3');
INSERT OR REPLACE INTO answers (username, stage, expected) VALUES ('$USERNAME', 4, '$FLAG4');
INSERT OR REPLACE INTO answers (username, stage, expected) VALUES ('$USERNAME', 5, '$FLAG5');
INSERT OR REPLACE INTO answers (username, stage, expected) VALUES ('$USERNAME', 6, '$FLAG6');
INSERT OR REPLACE INTO answers (username, stage, expected) VALUES ('$USERNAME', 7, '$FLAG7');
INSERT OR REPLACE INTO answers (username, stage, expected) VALUES ('$USERNAME', 8, '$FLAG8');
INSERT OR REPLACE INTO answers (username, stage, expected) VALUES ('$USERNAME', 9, '$FLAG9');
INSERT OR REPLACE INTO answers (username, stage, expected) VALUES ('$USERNAME', 10, '$FLAG10');
EOF

# ==========================================
# 0. ROADMAP (Talaba uchun boshlang'ich xarita)
# ==========================================
cat > "$HOME_DIR/ROADMAP.txt" <<'EOF'
================================================================================
🚩 LINUX PRAKTIKUM CTF — 10 TA AMALIY BOSQICH (YO'L XARITASI)
================================================================================

Salom, bo'lajak Linux mutaxassisi!
Ushbu platforma Linux asoslarini endigina tugatganlar uchun maxsus tayyorlangan.
Har bir bosqichda siz haqiqiy ma'muriy vazifani bajarasiz va YASHIRINGAN FLAGni topasiz!

📌 ASOSIY BUYRUQLAR:
  • check            — Topilgan flagni tekshirish (flag.txt faylidan o'qiydi)
  • check FLAG{...}  — Flagni to'g'ridan-to'g'ri terminalda kiritib tekshirish
  • status           — Hozirgi holat, progress bar va joriy vazifa sharti

🗺 BOSQICHLAR RO'YXATI:
  ┌────┬─────────────────────────────┬──────────────────────────────────────────┐
  │  # │ Mavzular & Buyruqlar        │ Vazifa mohiyati                          │
  ├────┼─────────────────────────────┼──────────────────────────────────────────┤
  │  1 │ ls -la, cd, cat, head, tail │ Yashirin papka va katta logdan flag topish│
  │  2 │ grep, cut, pipes (|)        │ Autentifikatsiya jurnalidan ustun ajratish│
  │  3 │ sort, uniq, pipes (|)       │ Minglab takrorlar orasidagi yagona signal│
  │  4 │ diff, comm                  │ Konfiguratsiya fayllari orasidagi farq   │
  │  5 │ sed, column                 │ Niqoblangan kalitni to'g'rilash va jadval│
  │  6 │ find, chmod, chown          │ Qulflangan yashirin faylni topish & ochish│
  │  7 │ git (log, show, diff)       │ Git tarixida o'chirilgan maxfiy commit   │
  │  8 │ crontab, at                 │ Rejalashtirilgan cron vazifasidan flag   │
  │  9 │ dpkg, apt                   │ .deb paket ichki tuzilishini o'rganish   │
  │ 10 │ tar, awk, cut (Master)      │ Arxivlangan hodisa fayllarini tergov     │
  └────┴─────────────────────────────┴──────────────────────────────────────────┘

🚀 Boshlash:
  cd ~/quiz1
  cat README.txt

Omad! 🎯
================================================================================
EOF
chmod 644 "$HOME_DIR/ROADMAP.txt"
chown "$USERNAME:$USERNAME" "$HOME_DIR/ROADMAP.txt"

# ==========================================
# QUIZ 1: ls -la, cd, cat, head, tail
# ==========================================
rm -rf "$HOME_DIR/quiz1"
mkdir -p "$HOME_DIR/quiz1/.hidden_vault"

{
    for i in $(seq 1 180); do
        echo "2026-09-18 10:$((i % 60)):$(( (i*7) % 60)) [INFO] Background worker[$i]: heartbeat active."
    done
    echo "2026-09-18 11:42:09 [AUDIT_ALERT] Security key generated: ${FLAG1}"
    for i in $(seq 182 220); do
        echo "2026-09-18 12:$((i % 60)):$(( (i*3) % 60)) [INFO] Routine cleanup task #$i finished."
    done
} > "$HOME_DIR/quiz1/.hidden_vault/.syslog_audit.log"

cat > "$HOME_DIR/quiz1/README.txt" <<'EOF'
====================================================================
📌 QUIZ 1: Yashirin fayllar va Log tahlili
====================================================================
🎯 Mavzular: ls -la, cd, cat, head, tail

📝 Vazifa:
  Oddiy 'ls' buyrug'i nuqta (.) bilan boshlanadigan yashirin fayl
  va papkalarni ko'rsatmaydi.
  1) Ushbu papkadagi yashirin papkani toping (ls -la).
  2) Yashirin papka ichiga kiring (cd).
  3) Ichidagi yashirin audit log faylini toping.
  4) 'tail' yoki 'head'/'cat' buyruqlari yordamida log ichidagi
     yashiringan FLAG{...} ni toping.
  5) Flagni 'flag.txt' fayliga yozing va 'check' buyrug'ini bering:
     echo "FLAG{...}" > ~/quiz1/flag.txt
     check

💡 Foydali buyruqlar:
  ls -la
  cd .hidden_vault
  tail -n 50 .syslog_audit.log
  tail -n 60 .syslog_audit.log | head -n 25

✅ Tekshirish:
  check
  (yoki to'g'ridan-to'g'ri: check FLAG{...})
====================================================================
EOF

chmod 644 "$HOME_DIR/quiz1/README.txt" "$HOME_DIR/quiz1/.hidden_vault/.syslog_audit.log"
chmod 755 "$HOME_DIR/quiz1/.hidden_vault"
chown -R "$USERNAME:$USERNAME" "$HOME_DIR/quiz1"
chmod 750 "$HOME_DIR/quiz1"

# ==========================================
# QUIZ 2: grep, cut, pipes (|)
# ==========================================
rm -rf "$HOME_DIR/quiz2"
mkdir -p "$HOME_DIR/quiz2"

{
    USERS=("alice" "bob" "charlie" "david" "elena" "frank" "george")
    IPS=("192.168.1.15" "10.0.0.4" "172.16.0.88" "192.168.10.100" "10.20.30.40")
    for i in $(seq 1 250); do
        U=${USERS[$((RANDOM % ${#USERS[@]}))]}
        IP=${IPS[$((RANDOM % ${#IPS[@]}))]}
        echo "2026-09-18 09:$((RANDOM % 60)):$((RANDOM % 60))|user=${U}|ip=${IP}|status=AUTH_FAIL|token=TOKEN-$((RANDOM % 9000 + 1000))"
    done
    echo "2026-09-18 10:14:33|user=superadmin|ip=10.0.99.1|status=FLAG_GRANTED|token=${FLAG2}"
    for i in $(seq 1 200); do
        U=${USERS[$((RANDOM % ${#USERS[@]}))]}
        IP=${IPS[$((RANDOM % ${#IPS[@]}))]}
        echo "2026-09-18 11:$((RANDOM % 60)):$((RANDOM % 60))|user=${U}|ip=${IP}|status=AUTH_FAIL|token=TOKEN-$((RANDOM % 9000 + 1000))"
    done
} | shuf > "$HOME_DIR/quiz2/.auth_stream.log"

cat > "$HOME_DIR/quiz2/README.txt" <<'EOF'
====================================================================
📌 QUIZ 2: Matn qidiruvi va Ustunlarni ajratish
====================================================================
🎯 Mavzular: grep, cut, quvurlar (|)

📝 Vazifa:
  Ushbu katalogda '.auth_stream.log' nomli yashirin log fayli mavjud.
  Unda yuzlab muvaffaqiyatsiz kirishlar yozilgan.
  Faqat bitta qatorda 'FLAG_GRANTED' holati bilan maxfiy flag qayd etilgan!

  1) 'grep' yordamida 'FLAG_GRANTED' qatorini toping.
  2) 'cut' buyrug'i yordamida ajratuvchi belgi (| va =) bo'yicha
     aniq 'FLAG{...}' qiymatini ajratib oling.
  3) Flagni 'flag.txt' fayliga saqlang va 'check' buyrug'ini bering.

💡 Foydali buyruqlar:
  grep "FLAG_GRANTED" .auth_stream.log
  grep "FLAG_GRANTED" .auth_stream.log | cut -d'|' -f5 | cut -d'=' -f2 > flag.txt

✅ Tekshirish:
  check
====================================================================
EOF

chmod 644 "$HOME_DIR/quiz2/README.txt" "$HOME_DIR/quiz2/.auth_stream.log"
chown -R "$USERNAME:$USERNAME" "$HOME_DIR/quiz2"
lock_dir "$HOME_DIR/quiz2"

# ==========================================
# QUIZ 3: sort, uniq, pipes (|)
# ==========================================
rm -rf "$HOME_DIR/quiz3"
mkdir -p "$HOME_DIR/quiz3"

NOISE_WORDS=(
    "SENSOR_PACKET_ID_9901_ALPHA" "TELEMETRY_CODE_BETA_220" "PING_RESPONSE_OK_NODE_1"
    "GPS_COORDINATE_SYNC_VAL_45" "NETWORK_FRAME_ACKNOWLEDGED" "KEEP_ALIVE_BEACON_404"
    "VOLTAGE_STABILIZER_ACTIVE" "ROUTER_GATEWAY_HEARTBEAT" "TEMP_SENSOR_CORE_OPTIMAL"
    "DATABASE_REPLICATION_TICK" "CPU_CLOCK_CALIBRATION_88" "SYS_MEMORY_PAGING_FLUSH"
)

{
    for word in "${NOISE_WORDS[@]}"; do
        TIMES=$((RANDOM % 35 + 15))
        for ((t=0; t<TIMES; t++)); do
            echo "$word"
        done
    done
    echo "$FLAG3"
    for word in "${NOISE_WORDS[@]}"; do
        TIMES=$((RANDOM % 20 + 10))
        for ((t=0; t<TIMES; t++)); do
            echo "$word"
        done
    done
} | shuf > "$HOME_DIR/quiz3/.telemetry_stream.txt"

cat > "$HOME_DIR/quiz3/README.txt" <<'EOF'
====================================================================
📌 QUIZ 3: Qatorlarni saralash va Unikal elementni topish
====================================================================
🎯 Mavzular: sort, uniq -u, quvurlar (|)

📝 Vazifa:
  '.telemetry_stream.txt' yashirin faylida 1000 dan ortiq qatorlar bor.
  Barcha shovqinli qatorlar 10-50 martadan takrorlangan.
  FAZODA FAQAT BIR DANA NOYOB (UNIKAL) QATOR BOR — u sizning flagingiz!

  Ko'z bilan topib bo'lmaydi. 'sort' va 'uniq -u' (faqat takrorlanmagan
  yagona qatorni chiqaruvchi kalit) orqali flagni toping!

💡 Foydali buyruqlar:
  sort .telemetry_stream.txt | uniq -u
  sort .telemetry_stream.txt | uniq -u > flag.txt

✅ Tekshirish:
  check
====================================================================
EOF

chmod 644 "$HOME_DIR/quiz3/README.txt" "$HOME_DIR/quiz3/.telemetry_stream.txt"
chown -R "$USERNAME:$USERNAME" "$HOME_DIR/quiz3"
lock_dir "$HOME_DIR/quiz3"

# ==========================================
# QUIZ 4: diff, comm
# ==========================================
rm -rf "$HOME_DIR/quiz4"
mkdir -p "$HOME_DIR/quiz4"

{
    for i in $(seq 1 120); do
        echo "iptables -A INPUT -p tcp --dport $((1000 + i)) -j ACCEPT"
        echo "iptables -A OUTPUT -p udp --sport $((2000 + i)) -j DROP"
    done
} > "$HOME_DIR/quiz4/firewall.conf"

{
    head -n 140 "$HOME_DIR/quiz4/firewall.conf"
    echo "# AUDIT_BACKDOOR_KEY: ${FLAG4}"
    tail -n +141 "$HOME_DIR/quiz4/firewall.conf"
} > "$HOME_DIR/quiz4/.firewall.conf.bak"

cat > "$HOME_DIR/quiz4/README.txt" <<'EOF'
====================================================================
📌 QUIZ 4: Fayllarni solishtirish va O'zgarishlarni topish
====================================================================
🎯 Mavzular: diff, comm

📝 Vazifa:
  Katalogda ikkita firewall konfiguratsiyasi bor:
  - 'firewall.conf' (original ochiq fayl)
  - '.firewall.conf.bak' (yashirin zaxira fayl)

  Zaxira faylga administrator tomonidan maxfiy izoh va flag qo'shilgan.
  Fayllar yuzlab qatordan iborat bo'lgani sababli qo'lda ko'rish samarasiz.
  'diff' yoki 'comm' buyrug'i yordamida ikkala fayl orasidagi yagona
  farqni aniqlang va flagni 'flag.txt' ga yozing.

💡 Foydali buyruqlar:
  diff firewall.conf .firewall.conf.bak
  diff -u firewall.conf .firewall.conf.bak | grep "FLAG{"
  comm -13 <(sort firewall.conf) <(sort .firewall.conf.bak)

✅ Tekshirish:
  check
====================================================================
EOF

chmod 644 "$HOME_DIR/quiz4/README.txt" "$HOME_DIR/quiz4/firewall.conf" "$HOME_DIR/quiz4/.firewall.conf.bak"
chown -R "$USERNAME:$USERNAME" "$HOME_DIR/quiz4"
lock_dir "$HOME_DIR/quiz4"

# ==========================================
# QUIZ 5: sed, column (cumm)
# ==========================================
rm -rf "$HOME_DIR/quiz5"
mkdir -p "$HOME_DIR/quiz5"

{
    echo "username:uid:role:department:secret_token"
    echo "root:0:superuser:IT:SYS-SEC-991"
    echo "webadmin:1001:operator:DevOps:WEB-TOKEN-442"
    echo "db_auditor:1002:analyst:Finance:DB-HASH-771"
    echo "sys_sentinel:1003:security:SOC:MASKEDFLAG--quiz5--sed--column--${SALT5}=="
    echo "net_engineer:1004:network:NOC:NET-CRED-120"
    echo "developer:1005:coder:Software:GIT-PUB-339"
} > "$HOME_DIR/quiz5/.classified_accounts.db"

cat > "$HOME_DIR/quiz5/README.txt" <<'EOF'
====================================================================
📌 QUIZ 5: Matnni qayta ishlash va Ustunli jadval
====================================================================
🎯 Mavzular: sed, column (cumm), stream editor

📝 Vazifa:
  '.classified_accounts.db' yashirin faylida tizim akkauntlari
  ikki nuqta (:) bilan ajratilgan ustunlarda yozilgan.

  1) 'column -t -s':' .classified_accounts.db' buyrug'i orqali
     ushbu ma'lumotlarni chiroyli jadval ko'rinishida o'qing.
  2) 'sys_sentinel' qatorida niqoblangan kalit bor:
     MASKEDFLAG--quiz5--sed--column--...==
  3) Ushbu niqobni 'sed' yordamida to'g'ri flag formatiga keltiring:
     - 'MASKEDFLAG--' so'zini 'FLAG{' ga almashtirish
     - '--' belgisini '_' ga almashtirish
     - '==' belgisini '}' ga almashtirish
     Natijada: FLAG{quiz5_sed_column_...} hosil bo'lishi kerak!

💡 Foydali buyruqlar:
  column -t -s':' .classified_accounts.db
  grep "MASKEDFLAG" .classified_accounts.db | cut -d':' -f5 | sed 's/MASKEDFLAG--/FLAG{/; s/--/_/g; s/==/}/' > flag.txt

✅ Tekshirish:
  check
====================================================================
EOF

chmod 644 "$HOME_DIR/quiz5/README.txt" "$HOME_DIR/quiz5/.classified_accounts.db"
chown -R "$USERNAME:$USERNAME" "$HOME_DIR/quiz5"
lock_dir "$HOME_DIR/quiz5"

# ==========================================
# QUIZ 6: find, chmod, chown
# ==========================================
rm -rf "$HOME_DIR/quiz6"
mkdir -p "$HOME_DIR/quiz6/backup_storage/logs/2026"
mkdir -p "$HOME_DIR/quiz6/backup_storage/db/archive"
mkdir -p "$HOME_DIR/quiz6/backup_storage/conf/active"

for i in $(seq 1 15); do
    echo "Dummy log data $i" > "$HOME_DIR/quiz6/backup_storage/logs/2026/service_$i.log"
    echo "Dummy config $i" > "$HOME_DIR/quiz6/backup_storage/conf/active/conf_$i.ini"
done

VAULT_FILE="$HOME_DIR/quiz6/backup_storage/db/archive/.vault_key.dat"
echo "$FLAG6" > "$VAULT_FILE"
# Faylga barcha huquqlarni 000 qilamiz — o'qib bo'lmaydi
chmod 000 "$VAULT_FILE"

cat > "$HOME_DIR/quiz6/README.txt" <<'EOF'
====================================================================
📌 QUIZ 6: Chuqur qidiruv va Fayl ruxsatlari (Permissions)
====================================================================
🎯 Mavzular: find, chmod, ls -l

📝 Vazifa:
  'backup_storage/' papkasi ichidagi ko'plab papkalar orasida
  yashirin '.vault_key.dat' fayli berkitilgan.
  Lekin uning ruxsati 000 (----------), ya'ni uni hatto ochib ham bo'lmaydi!

  1) 'find' buyrug'i orqali ushbu yashirin faylning to'liq yo'lini toping.
  2) 'chmod 644' (yoki 'chmod +r') yordamida o'zingizga o'qish huquqini bering.
  3) 'cat' orqali fayl ichidagi flagni o'qib 'flag.txt' ga saqlang.

💡 Foydali buyruqlar:
  find backup_storage/ -name ".*vault*"
  chmod 644 <fayl_yo'li>
  cat <fayl_yo'li> > flag.txt

✅ Tekshirish:
  check
====================================================================
EOF

chmod 644 "$HOME_DIR/quiz6/README.txt"
chown -R "$USERNAME:$USERNAME" "$HOME_DIR/quiz6"
# VAULT_FILE ni o'ziga tegishli qilib, ruxsatini 000 qilamiz
chmod 000 "$VAULT_FILE"
lock_dir "$HOME_DIR/quiz6"

# ==========================================
# QUIZ 7: git (log, show, diff)
# ==========================================
rm -rf "$HOME_DIR/quiz7"
mkdir -p "$HOME_DIR/quiz7/company-api"

(
    cd "$HOME_DIR/quiz7/company-api"
    git init -q
    git config user.name "Security Developer"
    git config user.email "dev@company.local"

    echo "# Company Microservice API" > README.md
    echo "def get_status(): return {'status': 'healthy'}" > api.py
    git add .
    git commit -q -m "Initial commit of company API"

    echo "API_SECRET_FLAG = \"$FLAG7\"" >> api.py
    git add api.py
    git commit -q -m "Add internal authentication credentials for testing"

    sed -i 's/API_SECRET_FLAG = .*/API_SECRET_FLAG = "REDACTED_BEFORE_PRODUCTION"/' api.py
    git add api.py
    git commit -q -m "CRITICAL SECURITY FIX: Remove leaked secret token from repository"
)

cat > "$HOME_DIR/quiz7/README.txt" <<'EOF'
====================================================================
📌 QUIZ 7: Git versiyalar nazorati — Yashirin commitlar
====================================================================
🎯 Mavzular: git log, git show, git diff

📝 Vazifa:
  'company-api' katalogida git repozitoriysi mavjud.
  Dasturchi api.py fayliga maxfiy flagni commit qilib, keyinroq
  xatosini tushunib 'Remove leaked secret token' deb uni o'chirib yuborgan!
  Faylning hozirgi holatida faqat 'REDACTED_BEFORE_PRODUCTION' yozuvi qolgan.

  1) 'cd company-api' ga kiring.
  2) 'git log' orqali o'tmishdagi commitlar tarixini ko'ring.
  3) 'git log -p' yoki 'git show <commit_hash>' yoki 'git diff HEAD~1'
     orqali o'chirilgan maxfiy flagni toping!
  4) Flagni ~/quiz7/flag.txt ga yozing.

💡 Foydali buyruqlar:
  cd company-api
  git log --oneline
  git log -p
  git show HEAD~1 | grep "FLAG{"

✅ Tekshirish:
  check
====================================================================
EOF

chmod 644 "$HOME_DIR/quiz7/README.txt"
chown -R "$USERNAME:$USERNAME" "$HOME_DIR/quiz7"
lock_dir "$HOME_DIR/quiz7"

# ==========================================
# QUIZ 8: crontab, at
# ==========================================
rm -rf "$HOME_DIR/quiz8"
mkdir -p "$HOME_DIR/quiz8"

# Talaba nomidan haqiqiy crontab o'rnatamiz
CRON_ENTRY="*/15 * * * * /usr/bin/python3 /opt/sync_service.py --token=\"${FLAG8}\" --audit=enabled >/dev/null 2>&1"
(crontab -l -u "$USERNAME" 2>/dev/null | grep -v "sync_service.py" || true; echo "$CRON_ENTRY") | crontab -u "$USERNAME" - 2>/dev/null || true

cat > "$HOME_DIR/quiz8/.at_scheduled_info.txt" <<EOF
[Tizim bildirishnomasi]
Linuxda bir martalik vazifalar uchun 'at' va 'batch' buyruqlari,
davriy (rejali) vazifalar uchun esa 'cron' va 'crontab' ishlatiladi.
Sizning hisobingiz uchun tizimda rejalashtirilgan cron vazifasi mavjud.
EOF

cat > "$HOME_DIR/quiz8/README.txt" <<'EOF'
====================================================================
📌 QUIZ 8: Rejalashtirilgan vazifalar (crontab va at)
====================================================================
🎯 Mavzular: crontab, at, rejalashtiruvchi jurnallar

📝 Vazifa:
  Linux tizimlarida xizmatlarni vaqti-vaqti bilan avtomatik yurgizish
  uchun 'cron' demoni va 'crontab' jadvali ishlatiladi.
  Tizim ma'muri sizning hisobingizga avtomatlashtirilgan zaxiralash
  topshirig'ini qo'shgan va parametr sifatida maxfiy token qoldirgan!

  1) 'crontab -l' buyrug'i orqali o'zingizning joriy cron jadvalingizni ko'ring.
  2) Rejalashtirilgan buyruqdagi --token="FLAG{...}" qismidan flagni oling.
  3) Flagni 'flag.txt' ga yozing va 'check' buyrug'ini bering.

💡 Foydali buyruqlar:
  crontab -l
  crontab -l | grep -o 'FLAG{[^"]*}' > flag.txt

✅ Tekshirish:
  check
====================================================================
EOF

chmod 644 "$HOME_DIR/quiz8/README.txt" "$HOME_DIR/quiz8/.at_scheduled_info.txt"
chown -R "$USERNAME:$USERNAME" "$HOME_DIR/quiz8"
lock_dir "$HOME_DIR/quiz8"

# ==========================================
# QUIZ 9: dpkg, apt
# ==========================================
rm -rf "$HOME_DIR/quiz9"
mkdir -p "$HOME_DIR/quiz9"

DEB_BUILD_DIR=$(mktemp -d /tmp/ctf_deb_build.XXXXXX)
mkdir -p "$DEB_BUILD_DIR/DEBIAN"
mkdir -p "$DEB_BUILD_DIR/etc/ctf-security"
mkdir -p "$DEB_BUILD_DIR/usr/share/doc/ctf-sec-package"

cat > "$DEB_BUILD_DIR/DEBIAN/control" <<EOF
Package: ctf-sec-package
Version: 1.0-1
Section: utils
Priority: optional
Architecture: all
Maintainer: CTF Admin <admin@ctf.local>
Description: Internal Diagnostic and Security Tool
 Custom debian package containing system diagnostic tools and licenses.
EOF

cat > "$DEB_BUILD_DIR/etc/ctf-security/diagnostic.conf" <<EOF
[DIAGNOSTIC_SERVICE]
enabled = true
log_level = info
EOF

cat > "$DEB_BUILD_DIR/usr/share/doc/ctf-sec-package/license_key.txt" <<EOF
CTF SECURITY SUITE LICENSE FILE
===============================
Authorized Licensee: $USERNAME
ACTIVATION_FLAG: $FLAG9
===============================
EOF

dpkg-deb --build "$DEB_BUILD_DIR" "$HOME_DIR/quiz9/.ctf-sec-package_1.0_all.deb" >/dev/null 2>&1
rm -rf "$DEB_BUILD_DIR"

cat > "$HOME_DIR/quiz9/README.txt" <<'EOF'
====================================================================
📌 QUIZ 9: Paket boshqaruvi — Debian (.deb) Paketlarini tahlil qilish
====================================================================
🎯 Mavzular: dpkg -c, dpkg -x, apt

📝 Vazifa:
  Ushbu katalogda '.ctf-sec-package_1.0_all.deb' nomli yashirin Debian
  paketi mavjud. Linux tizim ma'muri noma'lum paketlarni tizimga darhol
  'sudo dpkg -i' qilib o'rnatmasdan, avval uning tarkibini inspeksiya qilishi kerak!

  1) 'dpkg -c .ctf-sec-package_1.0_all.deb' yordamida paket ichidagi
     fayllar va kataloglar ro'yxatini ko'ring.
  2) 'dpkg -x .ctf-sec-package_1.0_all.deb extracted/' buyrug'i orqali
     paket fayllarini 'extracted' katalogiga oching.
  3) 'usr/share/doc/ctf-sec-package/license_key.txt' fayli ichidagi
     yashiringan flagni toping va 'flag.txt' ga yozing.

💡 Foydali buyruqlar:
  ls -la
  dpkg -c .ctf-sec-package_1.0_all.deb
  dpkg -x .ctf-sec-package_1.0_all.deb extracted/
  cat extracted/usr/share/doc/ctf-sec-package/license_key.txt

✅ Tekshirish:
  check
====================================================================
EOF

chmod 644 "$HOME_DIR/quiz9/README.txt" "$HOME_DIR/quiz9/.ctf-sec-package_1.0_all.deb"
chown -R "$USERNAME:$USERNAME" "$HOME_DIR/quiz9"
lock_dir "$HOME_DIR/quiz9"

# ==========================================
# QUIZ 10: tar, awk, cut (Master Incident Investigation)
# ==========================================
rm -rf "$HOME_DIR/quiz10"
mkdir -p "$HOME_DIR/quiz10"

INCIDENT_TEMP=$(mktemp -d /tmp/ctf_incident.XXXXXX)
mkdir -p "$INCIDENT_TEMP/incident"

cat > "$INCIDENT_TEMP/incident/network_summary.txt" <<EOF
Incident ID: INC-2026-9901
Description: Suspicious outbound network anomaly detected.
EOF

{
    echo "id,timestamp,service,status,flag_payload"
    for i in $(seq 1 420); do
        echo "$i,2026-09-18 14:$((i%60)):$(( (i*3)%60)),service_$((i%5)),NORMAL,NONE"
    done
    echo "421,2026-09-18 15:33:10,sshd,CRITICAL_BREACH,${FLAG10}"
    for i in $(seq 422 600); do
        echo "$i,2026-09-18 16:$((i%60)):$(( (i*7)%60)),service_$((i%5)),NORMAL,NONE"
    done
} > "$INCIDENT_TEMP/incident/security_events.csv"

tar -czf "$HOME_DIR/quiz10/.incident_dump.tar.gz" -C "$INCIDENT_TEMP" incident
rm -rf "$INCIDENT_TEMP"

cat > "$HOME_DIR/quiz10/README.txt" <<'EOF'
====================================================================
📌 QUIZ 10: YAKUNIY BOSQICH — Kiberhodisani tergov qilish (Master)
====================================================================
🎯 Mavzular: tar, awk, cut, barcha buyruqlar kombinatsiyasi

📝 Vazifa:
  Siz 9 ta sinovdan o'tdingiz. Bu yakuniy topshiriq!
  Ushbu katalogda '.incident_dump.tar.gz' nomli yashirin arxiv mavjud.

  1) 'ls -la' bilan arxivni ko'ring.
  2) 'tar -xzf .incident_dump.tar.gz' buyrug'i bilan arxivni oching.
  3) 'incident/security_events.csv' faylini 'awk' yordamida tahlil qiling:
     - 4-ustun (status) qiymati 'CRITICAL_BREACH' bo'lgan qatorni toping.
     - 5-ustundagi flagni ajratib oling.
  4) Flagni 'flag.txt' ga saqlang va 'check' buyrug'ini bering!

💡 Foydali buyruqlar:
  tar -xzf .incident_dump.tar.gz
  awk -F',' '$4 == "CRITICAL_BREACH" {print $5}' incident/security_events.csv > flag.txt

🏆 Barcha bosqichlarni yakunlab g'oliblik sertifikatingizni oling!

✅ Tekshirish:
  check
====================================================================
EOF

chmod 644 "$HOME_DIR/quiz10/README.txt" "$HOME_DIR/quiz10/.incident_dump.tar.gz"
chown -R "$USERNAME:$USERNAME" "$HOME_DIR/quiz10"
lock_dir "$HOME_DIR/quiz10"

echo "[+] $USERNAME uchun 10 ta quiz va yashiringan flaglar muvaffaqiyatli tayyorlandi."
