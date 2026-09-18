# 🚩 Linux Praktikum CTF — Boshlang'ichlar uchun 10 Bosqichli Amaliy Musobaqa

Ushbu platforma Linux asoslarini endigina tugatgan o'quvchilar va talabalar uchun maxsus ishlab chiqilgan **10 bosqichli amaliy CTF (Capture The Flag)** musobaqa va laboratoriya tizimidir.

Tizimda har bir bosqich uchun **yashiringan individual flag (`FLAG{...}`)** mavjud. Talabalar birinchi va ikkinchi versiyalardagi (v1 va v2) barcha muhim buyruqlarni chuqurlashtirilgan, lekin qiyinlashtirilmagan real ma'muriy stsenariylarda ishlatishadi.

Shuningdek yangi qo'shilgan buyruqlar: **`apt`**, **`dpkg`**, **`git`**, **`at`**, **`crontab`**, **`sed`**, **`uniq`**, **`cut`**, **`diff`**, **`comm`**, **`sort`**, **`column`** to'liq qamrab olingan.

---

## 📁 1. Loyiha Tuzilishi

```
ctf-v1/
├── install.sh              ← Serverga o'rnatish skripti (bir marta root sifatida)
├── uninstall.sh            ← Tozalash skripti (--students-only / --student / --all)
├── README.md               ← Ushbu to'liq qo'llanma
├── bin/
│   ├── check               ← /usr/local/bin/check (flagni tekshirish buyrug'i)
│   ├── status              ← /usr/local/bin/status (progress bar va topshirilgan flaglar)
│   ├── ctf-admin           ← /usr/local/bin/ctf-admin (terminal jonli monitoring paneli)
│   ├── ctf-web             ← /usr/local/bin/ctf-web (veb monitoring paneli)
│   └── ctf-reset           ← /usr/local/bin/ctf-reset (talaba progressini qayta tiklash)
├── admin/
│   ├── cli.py              ← Terminal TUI jonli monitoring skripti
│   └── server.py           ← Chiroyli zamonaviy Web Live Dashboard (pure Python)
├── setup/
│   ├── init_db.sh          ← SQLite bazasini (ctf.db) va jadvallarni yaratish
│   ├── generate_seed.sh    ← 10 ta quiz materiallari va yashiringan flaglarni generatsiya qilish
│   ├── provision_user.sh   ← Yangi talaba hisobini yaratish va xavfsiz sozlash
│   ├── add_students.sh     ← Ommaviy talaba qo'shish (--range yoki fayldan)
│   └── sudoers_ctf_general ← Sudo xavfsizlik qoidasi (faqat check va status uchun)
└── tasks/
    ├── quiz1_check.sh      ← 1-bosqich tekshiruvi (ls -la, cd, tail, head)
    ├── quiz2_check.sh      ← 2-bosqich tekshiruvi (grep, cut, pipes)
    ├── quiz3_check.sh      ← 3-bosqich tekshiruvi (sort, uniq -u)
    ├── quiz4_check.sh      ← 4-bosqich tekshiruvi (diff, comm)
    ├── quiz5_check.sh      ← 5-bosqich tekshiruvi (sed, column)
    ├── quiz6_check.sh      ← 6-bosqich tekshiruvi (find, chmod)
    ├── quiz7_check.sh      ← 7-bosqich tekshiruvi (git log, git show, git diff)
    ├── quiz8_check.sh      ← 8-bosqich tekshiruvi (crontab, at)
    ├── quiz9_check.sh      ← 9-bosqich tekshiruvi (dpkg, apt)
    └── quiz10_check.sh     ← 10-bosqich tekshiruvi (tar, awk, cut, incident master)
```

---

## 🎯 2. 10 ta Quiz Tafsilotlari va Yashirin Flaglar

Har bir talaba uchun har bir quizdagi flag unikal tarzda yaratiladi: `FLAG{quizN_mavzu_<unikal_xesh>}`. Bu talabalarning bir-biridan ko'chirishini oldini oladi.

| # | Mavzu & Buyruqlar | Stsenariy va Yashirin Joy | Foydalaniladigan Asosiy Buyruqlar |
|---|---|---|---|
| **1** | `ls -la`, `cd`, `cat`, `head`, `tail` | `~/quiz1/.hidden_vault/.syslog_audit.log` yashirin katalogi ichidagi 300 qatorli audit logining oxirgi qatorlarida flag berkitilgan. | `ls -la`, `cd .hidden_vault`, `tail -n 30 .syslog_audit.log` |
| **2** | `grep`, `cut`, pipes (`\|`) | `~/quiz2/.auth_stream.log` yashirin faylida 500 ta autentifikatsiya jurnali bor. Faqat bitta `FLAG_GRANTED` qatorida flag bor. | `grep "FLAG_GRANTED" .auth_stream.log \| cut -d'=' -f5` |
| **3** | `sort`, `uniq -u`, pipes (`\|`) | `~/quiz3/.telemetry_stream.txt` faylida 1500 ta shovqin qatorlari takrorlangan. Faqat 1 dona unikal qator mavjud va u flag! | `sort .telemetry_stream.txt \| uniq -u` |
| **4** | `diff`, `comm` | `firewall.conf` va yashirin `.firewall.conf.bak` fayllari solishtiriladi (diff/comm). Zaxiradagi yashirin qatorda flag bor. | `diff firewall.conf .firewall.conf.bak` yoki `comm -13` |
| **5** | `sed`, `column` (`cumm`) | `.classified_accounts.db` faylida niqoblangan kalit mavjud. `column -t -s':'` bilan ko'rib, `sed` bilan niqob yechiladi. | `column -t -s':' .classified_accounts.db`, `sed` |
| **6** | `find`, `chmod`, `chown` | `backup_storage/` ichida yashirin `.vault_key.dat` fayli bor. Ruxsati `000` (qulflangan). Talaba uni topib `chmod 644` qiladi. | `find backup_storage/ -name ".*vault*"`, `chmod 644` |
| **7** | `git` (`log`, `show`, `diff`) | `company-api` git repozitoriysida dasturchi maxfiy kalitni commit qilib, keyin o'chirib tashlagan. Tarix tahlil qilinadi. | `git log -p`, `git show HEAD~1`, `git diff HEAD~1` |
| **8** | `crontab`, `at` | Tizimda foydalanuvchiga rejalashtirilgan cron vazifasi bor. Uning buyrug'i parametrlarida flag yashiringan. | `crontab -l`, `grep "FLAG"` |
| **9** | `dpkg`, `apt` | `.ctf-sec-package_1.0_all.deb` yashirin Debian paketi. O'rnatmasdan ichini ko'rish va ochish talab qilinadi. | `dpkg -c .ctf-*.deb`, `dpkg -x .ctf-*.deb ext/` |
| **10** | `tar`, `awk`, `cut` (Master) | `.incident_dump.tar.gz` yashirin arxivi ochiladi. Ichidagi kiberxavfsizlik CSV fayli `awk` bilan filtrlanib oxirgi flag olinadi. | `tar -xzf .incident_dump.tar.gz`, `awk -F',' ...` |

---

## 🚀 3. O'rnatish (Serverda 1 marta)

Ubuntu/Debian serverida root yoki sudo huquqi bilan:

```bash
cd /home/user/ctf-v1
sudo bash install.sh
```

Bu buyruq:
1. Kerakli paketlarni (`sqlite3`, `openssl`, `git`, `cron`, `at`, `column`, `diffutils`, `dpkg`) tekshiradi va sozlaydi.
2. `/var/ctf/` papka tuzilishini va SQLite bazasini tayyorlaydi.
3. `/usr/local/bin/` ga `check`, `status`, `ctf-admin`, `ctf-web`, `ctf-reset` buyruqlarini joylaydi.
4. Talabalar uchun sudoers qoidalarini faollashtiradi.

---

## 👥 4. Talabalarni Qo'shish

### A) Bitta talaba qo'shish:
```bash
sudo bash /var/ctf/setup/provision_user.sh talaba1
# Parol so'ralsa:
sudo passwd talaba1
```

### B) Ommaviy (avtomatik) talaba qo'shish:
1. **Raqamlar oralig'i bo'yicha (masalan `talaba1` dan `talaba25` gacha):**
   ```bash
   sudo bash /var/ctf/setup/add_students.sh --range talaba 1 25
   ```
2. **Barcha talabalarga bitta standart parol berish:**
   ```bash
   sudo bash /var/ctf/setup/add_students.sh --range talaba 1 25 --password "LinuxCtf2026!"
   ```
3. **Fayldan o'qish orqali (`students.txt`):**
   ```bash
   sudo bash /var/ctf/setup/add_students.sh students.txt
   ```

Barcha yaratilgan login va parollar avtomatik ravishda `created_students.txt` va `created_students.csv` fayllariga saqlanadi.

---

## 🎮 5. Talaba Qo'llanmasi (SSH orqali ishlash)

Talaba o'z hisobiga SSH orqali kirgach:

1. **Yo'l xaritasi bilan tanishish:**
   ```bash
   cat ~/ROADMAP.txt
   ```

2. **Joriy bosqich va topshiriqni ko'rish:**
   ```bash
   status
   ```

3. **Birinchi bosqichga o'tish va vazifani o'qish:**
   ```bash
   cd ~/quiz1
   cat README.txt
   ```

4. **Yashiringan flagni topib tekshirish:**
   Topilgan flagni faylga yozib tekshirish:
   ```bash
   echo "FLAG{...}" > ~/quiz1/flag.txt
   check
   ```
   Yoki to'g'ridan-to'g'ri terminalda:
   ```bash
   check FLAG{...}
   ```

Agar flag to'g'ri bo'lsa:
- Tizim tabriklaydi va keyingi `quizN` papkasi avtomatik ochiladi!
- Talaba: `cd ~/quiz2 && cat README.txt` orqali keyingi topshiriqqa o'tadi.

Agar flag noto'g'ri bo'lsa:
- 2-chi va 4-chi xato urinishda tizim talabaga yo'naltiruvchi tushunarli **Maslahat (Hint)** va sintaksis shablonini ko'rsatadi.

---

## 📊 6. O'qituvchi uchun Jonli Monitoring

### 🖥 A) Terminal Jonli Paneli (TUI):
```bash
ctf-admin
```
Terminalda real-vaqt rejimida barcha talabalarning qaysi bosqichda ekanligi, kimlar online, nechta flag topshirgani va xatolar soni ko'rinib turadi.

### 🌐 B) Veb Jonli Dashboard:
```bash
# Serverni ishga tushirish (port 8080):
sudo ctf-web

# Orqa fonda ishga tushirish:
sudo ctf-web --daemon

# To'xtatish:
sudo ctf-web stop
```
Brauzerda: `http://<server-ip>:8080`
Admin paroli: `/var/ctf/admin.cred` faylida ko'rsatiladi.

---

## 🧹 7. Tozalash va Qayta Boshlash

- **Bitta talabani qayta boshlash (reset):**
  ```bash
  sudo ctf-reset talaba1
  ```

- **Yangi guruh uchun talabalarni tozalash (baza va arxiv saqlanadi):**
  ```bash
  sudo bash uninstall.sh --students-only
  ```

- **Bitta talabani tizimdan butunlay o'chirish:**
  ```bash
  sudo bash uninstall.sh --student talaba1
  ```

- **Butun CTF platformasini o'chirish:**
  ```bash
  sudo bash uninstall.sh --all
  ```
