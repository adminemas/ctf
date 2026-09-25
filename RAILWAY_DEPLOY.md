# 🚀 Railway Platformasiga CTF Loyihasini Joylash Qo'llanmasi

Ushbu loyiha Railway da Docker konteyneri orqali to'liq avtonom ishlaydigan qilib tayyorlangan:
- **SSH Server (Port 22):** Railway TCP Proxy orqali talabalar uchun ochiq bo'ladi.
- **Telegram Bot:** Talabalarni ro'yxatga olish, SSH login/parol tarqatish va admin paneli.
- **Web Dashboard (Port 8080):** Jonli monitoring veb-sahifasi.
- **Cron & At Daemon:** 8-bosqich vazifalari uchun fon jarayonlari.
- **Avtomatik Tiklash (Recovery):** Konteyner qayta yuklanganda barcha talabalar bazadan qayta tiklanadi.

---

## 📋 1. Railway da Loyiha Yaratish

1. [Railway.app](https://railway.app) ga kiring va GitHub orqali ro'yxatdan o'ting.
2. **"New Project"** -> **"Deploy from GitHub repo"** ni tanlang.
3. Ushbu `ctf-v1` repozitoriysini tanlang.
4. Railway avtomatik ravishda ildizdagi `Dockerfile` ni aniqlaydi va qurishni (build) boshlaydi.

---

## 🌐 2. TCP Proxy (SSH Port) Sozlash *(MUHIM)*

Talabalar tashqaridan SSH orqali ulanishi uchun Railway da TCP Proxy yoqilishi shart:

1. Railway dagi xizmatingiz (Service) ustiga bosing.
2. **Settings** bo'limiga o'ting.
3. **Networking** qismiga tushing.
4. **"TCP Proxy"** tugmasini bosing (**Add TCP Proxy**).
5. Konteyner porti sifatida **`22`** ni ko'rsating.
6. Railway sizga quyidagicha tashqi manzil beradi:
   * **Domain:** masalan `viaduct.proxy.rlwy.net` (yoki `monorail.proxy.rlwy.net`)
   * **Port:** masalan `18432`

---

## 🔑 3. O'zgaruvchilarni (Variables) Kiritish

Railway dagi xizmatingizning **Variables** bo'limiga o'ting va quyidagi o'zgaruvchilarni kiriting:

| O'zgaruvchi Nomi | Qiymati / Misol | Tavsifi |
|---|---|---|
| `BOT_TOKEN` | `123456789:ABCdefGh...` | BotFather dan olingan bot tokeni |
| `ADMIN_IDS` | `[123456789]` | Sizning Telegram ID ingiz (ro'yxat ko'rinishida) |
| `RAILWAY_TCP_PROXY_DOMAIN` | `viaduct.proxy.rlwy.net` | Railway bergan TCP Proxy domeni |
| `RAILWAY_TCP_PROXY_PORT` | `18432` | Railway bergan TCP Proxy porti |

> 💡 **Eslatma:** Agar siz Railway TCP Proxy ulasangiz, Telegram bot talabalarga avtomatik ravishda:
> `ssh talaba1@viaduct.proxy.rlwy.net -p 18432`
> ulanish buyrug'ini tayyor qilib beradi!

---

## 💾 4. Doimiy Xotira (Volume) Ulash *(Tavsiya etiladi)*

Konteyner yangilanganda ma'lumotlar bazasi saqlanib qolishi uchun:
1. Railway loyiha oynasida **"New"** -> **"Volume"** ni tanlang.
2. Volume ni CTF xizmatingizga bog'lang.
3. **Mount Path** ga quyidagini yozing:
   ```text
   /var/ctf
   ```
*(Bu orqali `/var/ctf/ctf.db` bazasi va barcha hisobotlar doimiy saqlanadi).*

---

## 📱 5. Boshqaruv (Admin Telegram Panel)

Siz server terminaliga kirmasdan, butun jarayonni Telegram botingiz orqali boshqarasiz:

1. Botingizga (`@ctf_projectbot`) kiring va **/admin** (yoki `/adminkubu`) buyrug'ini yuboring.
2. Sizga maxsus boshqaruv menyusi chiqadi:
   - **➕ Talaba qo'shish:** Bitta talaba (`ali`) yoki ommaviy talabalar (`talaba 1 20`) ni kiritasiz — bot o'zi barchasini yaratib, login/parollarini va ulanish buyrug'ini (.csv fayl ko'rinishida) sizga yuboradi.
   - **🔄 Talabani reset:** Qayta topshirishi kerak bo'lgan talabaning loginini kiritasiz — uning bosqichini darhol nollab/qayta ochib beradi.
   - **📥 CSV Hisobot:** Barcha talabalarning natijalari va statistikalarini Excel/CSV fayl qilib yuklab olish.
   - **📊 Statistika:** Kim qaysi quizda, necha kishi tugatgan, eng qiyin quiz qaysi.
   - **🏆 Top-15:** Jonli peshqadamlar reytingi.
   - **🔴 Qiynalganlar:** Ko'p xato qilayotgan yoki 30+ daqiqadan beri tiqilib qolganlar.
   - **👤 User izlash:** Istalgan talabaning to'liq diagnostikasi.
   - **📢 Xabar yuborish:** Barcha talabalarga e'lon xabari tarqatish.
