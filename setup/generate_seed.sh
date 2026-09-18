#!/bin/bash
# /var/ctf/setup/generate_seed.sh <username>
# Har bir talaba uchun 10 ta quiz materiallari, 3-4 tadan yashirin fayl/papkalar va
# qiziqarli vazifa qo'llanmalarini tayyorlaydi.

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

clean_quiz_dir() {
    local d="$1"
    mkdir -p "$d"
    find "$d" -mindepth 1 -delete 2>/dev/null || true
}

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

# Bazaga kutilgan flaglarni yozish
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
# 0. ROADMAP
# ==========================================
cat > "$HOME_DIR/ROADMAP.txt" <<'EOF'
================================================================================
🚩 LINUX PRAKTIKUM CTF — 10 TA AMALIY BOSQICH (YO'L XARITASI)
================================================================================

Salom! Ushbu musobaqa Linux asoslarini mustahkamlash uchun maxsus yaratilgan.
Har bir bosqichda sizga bir nechta yashirin fayl va papkalar beriladi.
Vazifangiz — kerakli ma'lumotni tahlil qilib, YASHIRINGAN FLAGni topish!

📌 ASOSIY BUYRUQLAR:
  • status           — Hozirgi bosqich, progress bar va joriy vazifani ko'rish
  • check            — Topilgan flagni tekshirish (flag.txt faylidan o'qiydi)
  • check FLAG{...}  — Flagni to'g'ridan-to'g'ri terminalda kiritib tekshirish
  • ctf-reset        — Joriy bosqich materiallarini qayta tiklash (yangilash)
  • ctf-reset --all  — Butun CTF progressini 1-bosqichdan qayta boshlash

🗺 BOSQICHLAR RO'YXATI:
  ┌────┬─────────────────────────────┬──────────────────────────────────────────┐
  │  # │ Mavzular & Buyruqlar        │ Vazifa mohiyati                          │
  ├────┼─────────────────────────────┼──────────────────────────────────────────┤
  │  1 │ ls -la, cd, cat, head, tail │ Yashirin papkalar va audit jurnali       │
  │  2 │ grep, cut, pipes (|)        │ Autentifikatsiya oqimidan token ajratish │
  │  3 │ sort, uniq, pipes (|)       │ Minglab takrorlar orasidagi unikal signal│
  │  4 │ diff, comm                  │ Konfiguratsiya zaxiralaridagi farqlar    │
  │  5 │ sed, column                 │ Niqoblangan kalit va formatlangan jadval │
  │  6 │ find, chmod, chown          │ Qulflangan yashirin faylni qidirish      │
  │  7 │ git (log, show, diff)       │ Git tarixida o'chirilgan maxfiy commit   │
  │  8 │ crontab, at                 │ Rejalashtirilgan cron vazifasidan flag   │
  │  9 │ dpkg, apt                   │ Debian paketlari orasidan kalit topish   │
  │ 10 │ tar, awk, cut (Master)      │ Kiberhodisa tergovi va yakuniy flag      │
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
clean_quiz_dir "$HOME_DIR/quiz1"
mkdir -p "$HOME_DIR/quiz1/.backup_vault"
mkdir -p "$HOME_DIR/quiz1/.temp_cache"
mkdir -p "$HOME_DIR/quiz1/.audit_vault"
mkdir -p "$HOME_DIR/quiz1/.debug_dump"

# Chalg'ituvchi 1
for i in $(seq 1 120); do echo "2025-11-04 08:$((i%60)):$((i%60)) [BACKUP_INFO] Snapshot chunk #$i archived successfully."; done > "$HOME_DIR/quiz1/.backup_vault/.sys_2025.log"
# Chalg'ituvchi 2
echo "CACHE_STATUS=OK; REFRESH_RATE=60s; PURGE_INTERVAL=3600s;" > "$HOME_DIR/quiz1/.temp_cache/.cache_status.cfg"
# Chalg'ituvchi 3
for i in $(seq 1 80); do echo "DEBUG: Trace point [$i] stack depth: $((RANDOM % 10))"; done > "$HOME_DIR/quiz1/.debug_dump/.trace_stack.log"

# Haqiqiy audit log
{
    for i in $(seq 1 190); do
        echo "2026-09-18 10:$((i % 60)):$(( (i*7) % 60)) [AUDIT_SYSTEM] Service worker #$i active heartbeat."
    done
    echo "2026-09-18 11:42:09 [AUDIT_SECURITY] Root session token generated: ${FLAG1}"
    for i in $(seq 192 230); do
        echo "2026-09-18 12:$((i % 60)):$(( (i*3) % 60)) [AUDIT_SYSTEM] Routine integrity verification passed."
    done
} > "$HOME_DIR/quiz1/.audit_vault/.system_audit.log"

cat > "$HOME_DIR/quiz1/README.txt" <<'EOF'
====================================================================
📌 QUIZ 1: Yashirin kataloglar va Jurnal tahlili
====================================================================
🎯 Mavzular: ls -la, cd, cat, head, tail

📝 Vazifa:
  Oddiy 'ls' buyrug'i nuqta (.) bilan boshlanadigan yashirin fayl
  va papkalarni ko'rsatmaydi.
  Ushbu katalogda bir nechta yashirin zaxira va ma'lumot papkalari mavjud.
  Sizga xavfsizlik auditi saqlanadigan audit papkasi — (.audit*) kerak!

  1) Barcha yashirin papkalarni ko'ring (ls -la).
  2) .audit* papkasi ichiga kiring.
  3) Ichidagi tizim auditi jurnalining (.system_audit*) oxirgi qismini
     o'qib, undagi maxfiy FLAG{...} ni toping.
  4) Topilgan flagni 'flag.txt' fayliga saqlang va 'check' buyrug'ini bering.

💡 Buyruqlar sintaksisi va ma'lumot:
  ls -la                      — Yashirin fayl va papkalarni ko'rsatish
  cd <papka_nomi>             — Papka ichiga kirish
  tail -n <son> <fayl>        — Faylning oxirgi <son> ta qatorini o'qish
  head -n <son> <fayl>        — Faylning boshidagi <son> ta qatorini o'qish

✅ Tekshirish:
  check
  (yoki: check FLAG{...})
====================================================================
EOF

chmod 644 "$HOME_DIR/quiz1/README.txt" \
          "$HOME_DIR/quiz1/.backup_vault/.sys_2025.log" \
          "$HOME_DIR/quiz1/.temp_cache/.cache_status.cfg" \
          "$HOME_DIR/quiz1/.debug_dump/.trace_stack.log" \
          "$HOME_DIR/quiz1/.audit_vault/.system_audit.log"
chmod 755 "$HOME_DIR/quiz1/.backup_vault" "$HOME_DIR/quiz1/.temp_cache" "$HOME_DIR/quiz1/.audit_vault" "$HOME_DIR/quiz1/.debug_dump"
chown -R "$USERNAME:$USERNAME" "$HOME_DIR/quiz1"
chmod 750 "$HOME_DIR/quiz1"

# ==========================================
# QUIZ 2: grep, cut, pipes (|)
# ==========================================
clean_quiz_dir "$HOME_DIR/quiz2"
mkdir -p "$HOME_DIR/quiz2"

# Chalg'ituvchi 1: FTP jurnali
{
    for i in $(seq 1 100); do
        echo "2026-09-18 08:$((RANDOM % 60)):$((RANDOM % 60))|service=ftp|action=FILE_RECV|bytes=$((RANDOM % 50000))|status=OK"
    done
} > "$HOME_DIR/quiz2/.ftp_transfers.log"

# Chalg'ituvchi 2: Eski arxiv
{
    for i in $(seq 1 120); do
        echo "2026-09-17 22:$((RANDOM % 60)):$((RANDOM % 60))|user=guest$i|ip=10.0.0.$((i%250))|status=AUTH_FAIL|token=NONE"
    done
} > "$HOME_DIR/quiz2/.auth_archive.log"

# Chalg'ituvchi 3: Debug log
{
    for i in $(seq 1 80); do
        echo "DEBUG: auth_middleware socket heartbeat check - ping $i ms"
    done
} > "$HOME_DIR/quiz2/.auth_debug.log"

# Haqiqiy kirish jurnali: .access_stream.log
{
    USERS=("alex" "dani" "sarah" "mike" "timur" "nilufar")
    IPS=("192.168.1.55" "10.10.4.12" "172.16.8.99" "192.168.0.105")
    for i in $(seq 1 200); do
        U=${USERS[$((RANDOM % ${#USERS[@]}))]}
        IP=${IPS[$((RANDOM % ${#IPS[@]}))]}
        echo "2026-09-18 09:$((RANDOM % 60)):$((RANDOM % 60))|user=${U}|ip=${IP}|status=AUTH_FAIL|token=TOKEN-$((RANDOM % 9000 + 1000))"
    done
    echo "2026-09-18 10:45:12|user=cyber_admin|ip=10.99.0.1|status=FLAG_GRANTED|token=${FLAG2}"
    for i in $(seq 1 180); do
        U=${USERS[$((RANDOM % ${#USERS[@]}))]}
        IP=${IPS[$((RANDOM % ${#IPS[@]}))]}
        echo "2026-09-18 11:$((RANDOM % 60)):$((RANDOM % 60))|user=${U}|ip=${IP}|status=AUTH_FAIL|token=TOKEN-$((RANDOM % 9000 + 1000))"
    done
} | shuf > "$HOME_DIR/quiz2/.access_stream.log"

cat > "$HOME_DIR/quiz2/README.txt" <<'EOF'
====================================================================
📌 QUIZ 2: Matn qidiruvi va Ustunlarni ajratish
====================================================================
🎯 Mavzular: grep, cut, quvurlar (|)

📝 Vazifa:
  Ushbu katalogda bir nechta yashirin jurnallar (.log fayllar) mavjud.
  Sizga serverga kirish oqimi qayd etilgan access stream — (.access*) jurnali kerak!
  Ushbu logda muvaffaqiyatli kirish ('FLAG_GRANTED') va uning xavfsizlik tokeni bor.

  1) Yashirin log fayllarni ko'ring (ls -la) va .access* jurnalini aniqlang.
  2) Muvaffaqiyatli kirish ('FLAG_GRANTED') qatorini qidirib toping.
  3) Ustun ajratuvchi belgilar (| va =) bo'yicha faqat 'FLAG{...}'
     qiymatini ajratib oling.
  4) Flagni 'flag.txt' fayliga saqlang va 'check' buyrug'ini bering.

💡 Buyruqlar sintaksisi va ma'lumot:
  grep "qidiruv_sozi" <fayl>   — Fayldan mos qatorlarni qidirish
  cut -d'<ajratuvchi>' -f<son> — Belgilangan ustunni ajratib olish
  buyruq1 | buyruq2            — Birinchi buyruq natijasini ikkinchisiga uzatish

✅ Tekshirish:
  check
====================================================================
EOF

chmod 644 "$HOME_DIR/quiz2/README.txt" \
          "$HOME_DIR/quiz2/.ftp_transfers.log" \
          "$HOME_DIR/quiz2/.auth_archive.log" \
          "$HOME_DIR/quiz2/.auth_debug.log" \
          "$HOME_DIR/quiz2/.access_stream.log"
chown -R "$USERNAME:$USERNAME" "$HOME_DIR/quiz2"
lock_dir "$HOME_DIR/quiz2"

# ==========================================
# QUIZ 3: sort, uniq, pipes (|)
# ==========================================
clean_quiz_dir "$HOME_DIR/quiz3"
mkdir -p "$HOME_DIR/quiz3"

# Chalg'ituvchi 1: traffic_a (barchasi takrorlangan)
{
    WORDS_A=("PKT_IPV4_ROUTER_1" "TCP_SYN_ACK_PACKET" "DNS_QUERY_RESOLVE" "NTP_TIME_SYNC_OK")
    for w in "${WORDS_A[@]}"; do
        for k in $(seq 1 40); do echo "$w"; done
    done
} | shuf > "$HOME_DIR/quiz3/.network_traffic_a.txt"

# Chalg'ituvchi 2: traffic_b (barchasi takrorlangan)
{
    WORDS_B=("BROADCAST_ARP_REQUEST" "DHCP_ACK_LEASE_RENEW" "ICMP_ECHO_REPLY_OK" "GATEWAY_MAC_ANNOUNCE")
    for w in "${WORDS_B[@]}"; do
        for k in $(seq 1 35); do echo "$w"; done
    done
} | shuf > "$HOME_DIR/quiz3/.network_traffic_b.txt"

# Chalg'ituvchi 3: system metrics (barchasi takrorlangan)
{
    WORDS_C=("CPU_USAGE_NORMAL_42" "RAM_CACHE_BUFFER_SYNC" "DISK_IO_READ_OK" "SWAP_FREE_100PCT")
    for w in "${WORDS_C[@]}"; do
        for k in $(seq 1 30); do echo "$w"; done
    done
} | shuf > "$HOME_DIR/quiz3/.system_metrics.txt"

# Haqiqiy telemetriya oqimi: faqat bitta unikal qator FLAG3
NOISE_WORDS=(
    "SENSOR_PACKET_ALPHA_99" "TELEMETRY_CORE_BETA_12" "PING_HEARTBEAT_ACK_NODE"
    "GPS_COORDINATE_SYNC_45" "VOLTAGE_STABILIZER_STABLE" "KEEP_ALIVE_BEACON_NODE"
    "DEVICE_STATUS_HEALTHY" "TEMPERATURE_ROOM_CELSIUS" "HUMIDITY_OPTIMAL_PERCENT"
    "PRESSURE_ATMOSPHERIC_BAR" "OPTICAL_FIBER_SIGNAL_OK" "BATTERY_LEVEL_CAPACITY_MAX"
)

{
    for word in "${NOISE_WORDS[@]}"; do
        TIMES=$((RANDOM % 30 + 15))
        for ((t=0; t<TIMES; t++)); do echo "$word"; done
    done
    echo "$FLAG3"
    for word in "${NOISE_WORDS[@]}"; do
        TIMES=$((RANDOM % 20 + 10))
        for ((t=0; t<TIMES; t++)); do echo "$word"; done
    done
} | shuf > "$HOME_DIR/quiz3/.sensor_telemetry.txt"

cat > "$HOME_DIR/quiz3/README.txt" <<'EOF'
====================================================================
📌 QUIZ 3: Qatorlarni saralash va Unikal elementni topish
====================================================================
🎯 Mavzular: sort, uniq -u, quvurlar (|)

📝 Vazifa:
  Ushbu katalogda bir nechta yashirin telemetriya va tarmoq oqimlari mavjud.
  Sizga datchiklar telemetriyasi — sensor telemetry (.sensor*) fayli kerak!
  Ushbu faylda shovqinli qatorlar takrorlangan, ammo FAQAT BIR DANA
  NOYOB (UNIKAL) qator bor — u siz qidirayotgan maxfiy flagdir!

  1) Yashirin fayllarni ko'ring (ls -la) va .sensor* faylini aniqlang.
  2) Saralash va noyob qatorlarni ajratish buyruqlari yordamida
     faqat 1 marta uchragan (takrorlanmagan) qatorni aniqlang.
  3) Flagni 'flag.txt' fayliga saqlang va 'check' buyrug'ini bering.

💡 Buyruqlar sintaksisi va ma'lumot:
  sort <fayl>                  — Qatorlarni alifbo bo'yicha tartiblash
  uniq -u                      — Faqat takrorlanmagan (yagona) qatorlarni chiqarish
  uniq -c                      — Qatorlarning takrorlanish soni bilan ko'rsatish
  buyruq1 | buyruq2            — Birinchi buyruq natijasini ikkinchisiga uzatish

✅ Tekshirish:
  check
====================================================================
EOF

chmod 644 "$HOME_DIR/quiz3/README.txt" \
          "$HOME_DIR/quiz3/.network_traffic_a.txt" \
          "$HOME_DIR/quiz3/.network_traffic_b.txt" \
          "$HOME_DIR/quiz3/.system_metrics.txt" \
          "$HOME_DIR/quiz3/.sensor_telemetry.txt"
chown -R "$USERNAME:$USERNAME" "$HOME_DIR/quiz3"
lock_dir "$HOME_DIR/quiz3"

# ==========================================
# QUIZ 4: diff, comm
# ==========================================
clean_quiz_dir "$HOME_DIR/quiz4"
mkdir -p "$HOME_DIR/quiz4"

# Asl fayl
{
    for i in $(seq 1 110); do
        echo "iptables -A INPUT -p tcp --dport $((1000 + i)) -j ACCEPT"
        echo "iptables -A OUTPUT -p udp --sport $((2000 + i)) -j DROP"
    done
} > "$HOME_DIR/quiz4/firewall.conf"

# Chalg'ituvchi zaxira 1 (farqi yo'q)
cp "$HOME_DIR/quiz4/firewall.conf" "$HOME_DIR/quiz4/.firewall_old.conf.bak"

# Chalg'ituvchi zaxira 2 (faqat test izohi)
{
    head -n 50 "$HOME_DIR/quiz4/firewall.conf"
    echo "# TEST_RULE: experimental log rule"
    tail -n +51 "$HOME_DIR/quiz4/firewall.conf"
} > "$HOME_DIR/quiz4/.firewall_dev.conf.bak"

# Haqiqiy zaxira (ichida flag bor)
{
    head -n 130 "$HOME_DIR/quiz4/firewall.conf"
    echo "# AUDIT_BACKDOOR_KEY: ${FLAG4}"
    tail -n +131 "$HOME_DIR/quiz4/firewall.conf"
} > "$HOME_DIR/quiz4/.firewall_production.conf.bak"

cat > "$HOME_DIR/quiz4/README.txt" <<'EOF'
====================================================================
📌 QUIZ 4: Konfiguratsiya zaxiralaridagi farqlarni aniqlash
====================================================================
🎯 Mavzular: diff, comm

📝 Vazifa:
  Katalogda joriy 'firewall.conf' konfiguratsiyasi va uning bir nechta
  yashirin zaxira nusxalari (.conf.bak) mavjud.
  Xavfsizlik tekshiruvi shuni ko'rsatdiki, administrator zaxira nusxalaridan
  biriga ruxsatsiz maxfiy auditi kalitini ('AUDIT_BACKDOOR_KEY') kiritgan.

  Fayllar yuzlab qatordan iborat bo'lgani sababli ularni qo'lda ko'rib bo'lmaydi.
  Sizga asosiy production zaxirasi — (.firewall_production*) fayli kerak!

  1) Yashirin zaxira nusxalarini ko'ring (ls -la) va production zaxirasini aniqlang.
  2) Fayllarni solishtirish vositasi (diff) yordamida firewall.conf va
     ushbu production zaxirasi orasidagi qo'shilgan maxsus qatorni aniqlang.
  3) Qo'shilgan maxfiy flagni 'flag.txt' ga saqlang va 'check' qiling.

💡 Buyruqlar sintaksisi va ma'lumot:
  diff <fayl1> <fayl2>         — Ikkita fayl orasidagi farqlarni ko'rsatish
  diff -u <fayl1> <fayl2>      — Qo'shilgan (+) va o'chirilgan (-) qatorlar ko'rinishida
  comm -13 <fayl1> <fayl2>     — Faqat ikkinchi faylda bor qatorlarni ko'rsatish (saralangan fayllar uchun)

✅ Tekshirish:
  check
====================================================================
EOF

chmod 644 "$HOME_DIR/quiz4/README.txt" \
          "$HOME_DIR/quiz4/firewall.conf" \
          "$HOME_DIR/quiz4/.firewall_old.conf.bak" \
          "$HOME_DIR/quiz4/.firewall_dev.conf.bak" \
          "$HOME_DIR/quiz4/.firewall_production.conf.bak"
chown -R "$USERNAME:$USERNAME" "$HOME_DIR/quiz4"
lock_dir "$HOME_DIR/quiz4"

# ==========================================
# QUIZ 5: sed, column (cumm)
# ==========================================
clean_quiz_dir "$HOME_DIR/quiz5"
mkdir -p "$HOME_DIR/quiz5"

# Chalg'ituvchi 1
{
    echo "service:port:protocol:status"
    echo "sshd:22:tcp:running"
    echo "nginx:80:tcp:running"
    echo "mysql:3306:tcp:active"
    echo "redis:6379:tcp:active"
} > "$HOME_DIR/quiz5/.system_services.db"

# Chalg'ituvchi 2
{
    echo "app:version:environment:owner"
    echo "frontend:2.4:production:web_team"
    echo "backend_api:1.9:production:dev_team"
    echo "billing:3.1:staging:finance_team"
} > "$HOME_DIR/quiz5/.deployment_registry.db"

# Haqiqiy fayl: .classified_registry.db
{
    echo "username:uid:role:department:secret_token"
    echo "root:0:superuser:IT:SYS-SEC-991"
    echo "webadmin:1001:operator:DevOps:WEB-TOKEN-442"
    echo "db_auditor:1002:analyst:Finance:DB-HASH-771"
    echo "sec_sentinel:1003:security:SOC:MASKEDFLAG--quiz5--sed--column--${SALT5}=="
    echo "net_engineer:1004:network:NOC:NET-CRED-120"
    echo "developer:1005:coder:Software:GIT-PUB-339"
} > "$HOME_DIR/quiz5/.classified_registry.db"

cat > "$HOME_DIR/quiz5/README.txt" <<'EOF'
====================================================================
📌 QUIZ 5: Formatlangan jadval va Niqoblangan kalitni tiklash
====================================================================
🎯 Mavzular: sed, column (cumm), stream editor

📝 Vazifa:
  Ushbu katalogda bir nechta yashirin tizim ma'lumotlar ro'yxatlari (.db fayllar) bor.
  Sizga maxfiy xavfsizlik registri — classified registry (.classified*) fayli kerak!
  Undagi xodimlar va ularning maxfiy tokenlari saqlanadi.

  1) Yashirin fayllarni ko'ring (ls -la) va .classified* faylini aniqlang.
  2) 'column -t -s\':\'' buyrug'i orqali ushbu faylni tartibli jadval shaklida o'qing.
  3) Undagi 'MASKEDFLAG--...' niqoblangan kalitini toping.
  4) Ushbu matnni 'sed' yordamida to'g'ri FLAG formatiga keltiring:
     - 'MASKEDFLAG--' so'zini 'FLAG{' ga almashtirish
     - Barcha '--' belgilarini '_' (pastki chiziq) ga almashtirish
     - Oxiridagi '==' belgisini '}' ga almashtirish
     Natijada to'liq flag hosil bo'lishi kerak!
  4) Tayyor flagni 'flag.txt' ga yozing va 'check' buyrug'ini bering.

💡 Buyruqlar sintaksisi va ma'lumot:
  column -t -s':' <fayl>       — Ikki nuqta bilan ajratilgan ustunlarni tekis jadvalga aylantirish
  sed 's/qidiruv/almashtirish/g' — Matndagi belgilarni yangisiga almashtirish

✅ Tekshirish:
  check
====================================================================
EOF

chmod 644 "$HOME_DIR/quiz5/README.txt" \
          "$HOME_DIR/quiz5/.system_services.db" \
          "$HOME_DIR/quiz5/.deployment_registry.db" \
          "$HOME_DIR/quiz5/.classified_registry.db"
chown -R "$USERNAME:$USERNAME" "$HOME_DIR/quiz5"
lock_dir "$HOME_DIR/quiz5"

# ==========================================
# QUIZ 6: find, chmod, chown
# ==========================================
clean_quiz_dir "$HOME_DIR/quiz6"
mkdir -p "$HOME_DIR/quiz6/backup_storage/logs/2026"
mkdir -p "$HOME_DIR/quiz6/backup_storage/db/archive"
mkdir -p "$HOME_DIR/quiz6/backup_storage/conf/active"
mkdir -p "$HOME_DIR/quiz6/backup_storage/cache/temp"

for i in $(seq 1 12); do
    echo "Routine log $i" > "$HOME_DIR/quiz6/backup_storage/logs/2026/service_$i.log"
    echo "System config $i" > "$HOME_DIR/quiz6/backup_storage/conf/active/conf_$i.ini"
done

# Chalg'ituvchi 1 (ochiq soxta fayl)
echo "Bu soxta kalit: FAKE_KEY_12345 (Haqiqiy kalit boshqa yashirin faylda!)" > "$HOME_DIR/quiz6/backup_storage/db/archive/.fake_vault.key"
chmod 644 "$HOME_DIR/quiz6/backup_storage/db/archive/.fake_vault.key"

# Chalg'ituvchi 2
echo "CACHE_EXPIRED" > "$HOME_DIR/quiz6/backup_storage/cache/temp/.cache_data.tmp"
chmod 644 "$HOME_DIR/quiz6/backup_storage/cache/temp/.cache_data.tmp"

# Haqiqiy qulflangan fayl: .vault_key.dat (ruxsati 000)
VAULT_FILE="$HOME_DIR/quiz6/backup_storage/db/archive/.vault_key.dat"
echo "$FLAG6" > "$VAULT_FILE"
chmod 000 "$VAULT_FILE"

cat > "$HOME_DIR/quiz6/README.txt" <<'EOF'
====================================================================
📌 QUIZ 6: Chuqur qidiruv va Fayl ruxsatlari (Permissions)
====================================================================
🎯 Mavzular: find, chmod, ls -l

📝 Vazifa:
  'backup_storage/' papkasi ichidagi ko'plab papkalar orasida bir nechta
  yashirin fayllar mavjud.
  Administrator muhim xavfsizlik kaliti saqlangan yashirin faylning
  barcha ruxsatlarini olib tashlagan (000 — ----------), ya'ni uni
  ochishga ruxsat yo'q.
  Shuningdek, ehtiyot bo'ling: katalogda chalg'ituvchi soxta fayllar ham bor!

  1) 'find' buyrug'i orqali katalog ichidagi barcha yashirin fayllarni qidiring.
  2) Ularning ruxsatlarini ko'zdan kechirib, aynan ruxsati qulflangan (000)
     haqiqiy kalit faylini aniqlang.
  3) Unga o'qish huquqini bering va ichidagi haqiqiy flagni o'qing.
  4) Flagni 'flag.txt' ga saqlang va 'check' buyrug'ini bering.

💡 Buyruqlar sintaksisi va ma'lumot:
  find <katalog> -name "<qolip>" — Fayl nomi qolipi bo'yicha qidirish
  ls -l <fayl>                   — Faylning huquqlari va egasini ko'rish
  chmod <ruxsat> <fayl>          — Fayl huquqini o'zgartirish (masalan 644 yoki +r)

✅ Tekshirish:
  check
====================================================================
EOF

chmod 644 "$HOME_DIR/quiz6/README.txt"
chown -R "$USERNAME:$USERNAME" "$HOME_DIR/quiz6"
chmod 000 "$VAULT_FILE"
lock_dir "$HOME_DIR/quiz6"

# ==========================================
# QUIZ 7: git (log, show, diff)
# ==========================================
clean_quiz_dir "$HOME_DIR/quiz7"
mkdir -p "$HOME_DIR/quiz7/company-api"

(
    cd "$HOME_DIR/quiz7/company-api"
    git init -q
    git config user.name "Lead Developer"
    git config user.email "lead@company.local"

    echo "# Company Core Service API" > README.md
    echo "def status(): return {'status': 'ok'}" > service.py
    git add .
    git commit -q -m "Initial commit of company core service"

    echo "DATABASE_HOST = 'db.internal.net'" >> service.py
    git add service.py
    git commit -q -m "Configure internal database endpoint"

    echo "SECRET_ADMIN_FLAG = \"$FLAG7\"" >> service.py
    git add service.py
    git commit -q -m "Add staging authentication secret for internal testing"

    sed -i 's/SECRET_ADMIN_FLAG = .*/SECRET_ADMIN_FLAG = "REDACTED_FOR_SECURITY"/' service.py
    git add service.py
    git commit -q -m "SECURITY PATCH: Sanitize codebase and revoke leaked secret token"
)

cat > "$HOME_DIR/quiz7/README.txt" <<'EOF'
====================================================================
📌 QUIZ 7: Git versiyalar nazorati — Yashirin commitlar
====================================================================
🎯 Mavzular: git log, git show, git diff

📝 Vazifa:
  'company-api' katalogida kompaniya dasturining Git repozitoriysi joylashgan.
  Dasturchi o'tmishdagi commitlardan birida maxfiy admin flagini tasodifan
  kodga qo'shib yuborgan va xatosini sezgach, keyingi versiyada uni
  o'chirib, o'rniga 'REDACTED_FOR_SECURITY' yozib ketgan.

  Hozirgi fayllarda flag yo'q. Uni topish uchun Git tarixini o'rganishingiz kerak!
  1) Repozitoriy katalogiga kiring.
  2) Bajarilgan barcha commitlar tarixini ko'rib chiqing.
  3) Tarixdagi commit farqlarini tekshirib, dasturchi tomonidan
     o'chirilgan maxfiy flagni tiklab oling.
  4) Flagni ~/quiz7/flag.txt ga yozing va 'check' buyrug'ini bering.

💡 Buyruqlar sintaksisi va ma'lumot:
  git log                      — Commitlar tarixini ko'rish
  git log -p                   — Commitlarda kiritilgan o'zgarishlar (diff)ni ko'rish
  git show <commit_hash>       — Muayyan commitning batafsil o'zgarishlarini ko'rish
  git diff HEAD~1              — Oxirgi commit bilan oldingi commit farqini ko'rish

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
clean_quiz_dir "$HOME_DIR/quiz8"
mkdir -p "$HOME_DIR/quiz8"

# Haqiqiy crontab o'rnatish
CRON_ENTRY="*/15 * * * * /usr/bin/python3 /opt/maintenance.py --token=\"${FLAG8}\" --mode=silent >/dev/null 2>&1"
(crontab -l -u "$USERNAME" 2>/dev/null | grep -v "maintenance.py" || true; echo "$CRON_ENTRY") | crontab -u "$USERNAME" - 2>/dev/null || true

# Chalg'ituvchi 1: tizim qoidalari
cat > "$HOME_DIR/quiz8/.crontab_system_rules.txt" <<EOF
# Cron format:
# m h dom mon dow   command
# * * * * *         har daqiqada
EOF

# Chalg'ituvchi 2: at buyrug'i misollari
cat > "$HOME_DIR/quiz8/.at_scheduled_tasks.txt" <<EOF
[AT Queue Manager]
Bir martalik vazifalarni rejalashtirish:
  echo "/usr/bin/backup" | at 23:00
EOF

# Chalg'ituvchi 3: log fayl
cat > "$HOME_DIR/quiz8/.cron_audit.log" <<EOF
2026-09-18 12:00:01 cron service daemon started.
2026-09-18 12:15:01 cron job executed for current user.
EOF

cat > "$HOME_DIR/quiz8/README.txt" <<'EOF'
====================================================================
📌 QUIZ 8: Rejalashtirilgan vazifalar (crontab va at)
====================================================================
🎯 Mavzular: crontab, at, avtomatlashtirish

📝 Vazifa:
  Linux tizimlarida ma'lum vaqt oralig'ida avtomatik ishlaydigan vazifalar
  'cron' xizmati va 'crontab' jadvali yordamida boshqariladi.
  Tizim administratori sizning hisobingizga avtomatik texnik xizmat
  topshirig'ini biriktirgan va buyruq parametrlari orasida maxfiy token qoldirgan.

  1) Joriy foydalanuvchining rejalashtirilgan cron jadvalini ko'ring.
  2) Biriktirilgan buyruq parametrlari orasidagi maxfiy FLAG{...} ni toping.
  3) Flagni 'flag.txt' ga saqlang va 'check' buyrug'ini bering.

💡 Buyruqlar sintaksisi va ma'lumot:
  crontab -l                   — Foydalanuvchining joriy cron topshiriqlarini ko'rish
  grep "namuna"                — Chiqqan natijadan kerakli so'zni filtrlash

✅ Tekshirish:
  check
====================================================================
EOF

chmod 644 "$HOME_DIR/quiz8/README.txt" \
          "$HOME_DIR/quiz8/.crontab_system_rules.txt" \
          "$HOME_DIR/quiz8/.at_scheduled_tasks.txt" \
          "$HOME_DIR/quiz8/.cron_audit.log"
chown -R "$USERNAME:$USERNAME" "$HOME_DIR/quiz8"
lock_dir "$HOME_DIR/quiz8"

# ==========================================
# QUIZ 9: dpkg, apt
# ==========================================
clean_quiz_dir "$HOME_DIR/quiz9"
mkdir -p "$HOME_DIR/quiz9"

make_deb() {
    local PKG_NAME="$1"
    local PKG_VER="$2"
    local DESC="$3"
    local DOC_FILE="$4"
    local DOC_CONTENT="$5"
    local OUT_FILE="$6"

    local BDIR=$(mktemp -d /tmp/deb_mk.XXXXXX)
    mkdir -p "$BDIR/DEBIAN" "$BDIR/usr/share/doc/$PKG_NAME"
    cat > "$BDIR/DEBIAN/control" <<EOF
Package: $PKG_NAME
Version: $PKG_VER
Section: utils
Priority: optional
Architecture: all
Maintainer: CTF Packager <pkg@ctf.local>
Description: $DESC
EOF
    echo "$DOC_CONTENT" > "$BDIR/usr/share/doc/$PKG_NAME/$DOC_FILE"
    dpkg-deb --build "$BDIR" "$OUT_FILE" >/dev/null 2>&1
    rm -rf "$BDIR"
}

# Chalg'ituvchi paket 1: tarmoq paketi
make_deb "net-diagnostics" "0.9" "Network inspection utility" "README" "Standard network utility suite." "$HOME_DIR/quiz9/.net-diagnostics_0.9_all.deb"

# Chalg'ituvchi paket 2: zaxiralash paketi
make_deb "backup-agent" "1.2" "Automated backup agent" "CHANGELOG" "Version 1.2: routine stability fixes." "$HOME_DIR/quiz9/.backup-agent_1.2_all.deb"

# Haqiqiy paket: ctf-sec-suite (ichida litsenziya va flag bor)
make_deb "ctf-sec-suite" "1.0" "Security and license verification tool" "license_key.txt" \
"CTF SUITE ACTIVATION CERTIFICATE
================================
Authorized User: $USERNAME
ACTIVATION_FLAG: $FLAG9
================================" "$HOME_DIR/quiz9/.ctf-sec-suite_1.0_all.deb"

cat > "$HOME_DIR/quiz9/README.txt" <<'EOF'
====================================================================
📌 QUIZ 9: Paket boshqaruvi — Debian (.deb) Paketlarini tahlil qilish
====================================================================
🎯 Mavzular: dpkg -c, dpkg -x, apt

📝 Vazifa:
  Ushbu katalogda bir nechta yashirin Debian (.deb) paketlari mavjud.
  Malakali Linux mutaxassisi noma'lum paketlarni tizimga darhol o'rnatmasdan
  ('dpkg -i' qilib tizimga zarar yetkazishi mumkin), avval ularning
  ichki tarkibini inspeksiya qilishi zarur.

  1) Yashirin deb paketlarni ko'ring (ls -la) va xavfsizlik to'plami (.ctf-sec*) paketini aniqlang.
  2) 'dpkg -c' bilan paketning ichki fayllar ro'yxatini ko'rib chiqing.
  3) Ushbu paketni alohida katalogga oching ('dpkg -x').
  4) Ichidagi litsenziya/faollashtirish faylidan flagni o'qib,
     'flag.txt' ga saqlang va 'check' buyrug'ini bering.

💡 Buyruqlar sintaksisi va ma'lumot:
  dpkg -c <paket.deb>          — Paket ichidagi fayllar ro'yxatini ko'rish
  dpkg -x <paket.deb> <katalog>— Paket fayllarini ko'rsatilgan papkaga ochish
  dpkg -I <paket.deb>          — Paket haqidagi umumiy ma'lumot (metadata)ni ko'rish

✅ Tekshirish:
  check
====================================================================
EOF

chmod 644 "$HOME_DIR/quiz9/README.txt" \
          "$HOME_DIR/quiz9/.net-diagnostics_0.9_all.deb" \
          "$HOME_DIR/quiz9/.backup-agent_1.2_all.deb" \
          "$HOME_DIR/quiz9/.ctf-sec-suite_1.0_all.deb"
chown -R "$USERNAME:$USERNAME" "$HOME_DIR/quiz9"
lock_dir "$HOME_DIR/quiz9"

# ==========================================
# QUIZ 10: tar, awk, cut (Master Incident Investigation)
# ==========================================
clean_quiz_dir "$HOME_DIR/quiz10"
mkdir -p "$HOME_DIR/quiz10"

# Chalg'ituvchi arxiv 1
TDIR1=$(mktemp -d /tmp/dump_a.XXXXXX)
mkdir -p "$TDIR1/traffic"
for i in $(seq 1 60); do echo "Packet #$i: length 128 bytes TCP ACK" >> "$TDIR1/traffic/capture.log"; done
tar -czf "$HOME_DIR/quiz10/.traffic_capture.tar.gz" -C "$TDIR1" traffic
rm -rf "$TDIR1"

# Chalg'ituvchi arxiv 2
TDIR2=$(mktemp -d /tmp/dump_b.XXXXXX)
mkdir -p "$TDIR2/crash_dumps"
echo "Kernel panic trace: none. Status: normal reboot." > "$TDIR2/crash_dumps/kernel.log"
tar -czf "$HOME_DIR/quiz10/.system_crash_dump.tar.gz" -C "$TDIR2" crash_dumps
rm -rf "$TDIR2"

# Haqiqiy hodisa arxivi: .incident_investigation.tar.gz
TDIR3=$(mktemp -d /tmp/dump_c.XXXXXX)
mkdir -p "$TDIR3/incident"
cat > "$TDIR3/incident/investigation_memo.txt" <<EOF
SECURITY INCIDENT REPORT
Status: Critical anomalous outbound traffic analyzed.
Target: Identify breach payload in security_events.csv
EOF

{
    echo "id,timestamp,service,status,flag_payload"
    for i in $(seq 1 350); do
        echo "$i,2026-09-18 14:$((i%60)):$(( (i*3)%60)),service_$((i%5)),NORMAL,NONE"
    done
    echo "351,2026-09-18 15:33:10,sshd,CRITICAL_BREACH,${FLAG10}"
    for i in $(seq 352 500); do
        echo "$i,2026-09-18 16:$((i%60)):$(( (i*7)%60)),service_$((i%5)),NORMAL,NONE"
    done
} > "$TDIR3/incident/security_events.csv"

tar -czf "$HOME_DIR/quiz10/.incident_investigation.tar.gz" -C "$TDIR3" incident
rm -rf "$TDIR3"

cat > "$HOME_DIR/quiz10/README.txt" <<'EOF'
====================================================================
📌 QUIZ 10: YAKUNIY BOSQICH — Kiberhodisani tergov qilish (Master)
====================================================================
🎯 Mavzular: tar, awk, cut, barcha vositalar kombinatsiyasi

📝 Vazifa:
  Tabriklaymiz! Siz 9 ta bosqichni muvaffaqiyatli yakunlab, oxirgi
  master sinovga yetib keldingiz.
  Ushbu katalogda bir nechta yashirin arxivlar (.tar.gz) mavjud.

  1) Yashirin arxivlarni ko'ring (ls -la) va kiberhodisa tergovi (.incident*) arxivini aniqlang.
  2) Arxivni oching ('tar -xzf').
  3) Ochilgan 'incident' papkasi ichidagi 'security_events.csv'
     jadvalini tahlil qiling.
  4) Jadvaldagi normal hodisalar orasidan status ustuni
     'CRITICAL_BREACH' bo'lgan qatorni 'awk' yordamida topib,
     oxirgi ustunidagi yakuniy g'alaba flagini ajratib oling!
  5) Flagni 'flag.txt' ga saqlang va 'check' buyrug'ini bering.

💡 Buyruqlar sintaksisi va ma'lumot:
  tar -tf <arxiv.tar.gz>       — Arxiv ichidagi fayllar ro'yxatini ko'rish
  tar -xzf <arxiv.tar.gz>      — Gzip bilan siqilgan tar arxivini ochish
  awk -F',' '$3=="qiymat" {print $5}' <fayl> — CSV ustunini tekshirib, kerakli ustunni chiqarish

🏆 Yakuniy topshiriqni bajarib, g'oliblik sertifikatingizni qo'lga kiriting!

✅ Tekshirish:
  check
====================================================================
EOF

chmod 644 "$HOME_DIR/quiz10/README.txt" \
          "$HOME_DIR/quiz10/.traffic_capture.tar.gz" \
          "$HOME_DIR/quiz10/.system_crash_dump.tar.gz" \
          "$HOME_DIR/quiz10/.incident_investigation.tar.gz"
chown -R "$USERNAME:$USERNAME" "$HOME_DIR/quiz10"
lock_dir "$HOME_DIR/quiz10"

echo "[+] $USERNAME uchun 10 ta quiz, 3-4 tadan yashirin fayllar va topshiriqlar tayyorlandi."
