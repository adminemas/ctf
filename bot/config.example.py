# CTF Bot konfiguratsiyasi
# Bu faylni to'ldirib config.py sifatida saqlang

# BotFather dan olingan token
BOT_TOKEN = "YOUR_BOT_TOKEN_HERE"

# Server IP manzili.
# "auto" deb yozsangiz, hostname -I orqali avtomatik aniqlanadi.
SERVER_IP = "auto"
# Yoki aniq IP: SERVER_IP = "192.168.1.100"

# SQLite baza yo'li
DB_PATH = "/var/ctf/ctf.db"

# Telegram admin ID lari (ular /astats, /atop, /astuck, /auser buyruqlarini ishlatishi mumkin)
# O'z Telegram ID ingizni @userinfobot dan bilib olishingiz mumkin
ADMIN_IDS = [
    123456789,   # Admin 1 (bu yerga o'z ID ingizni yozing)
    # 987654321, # Admin 2
]
