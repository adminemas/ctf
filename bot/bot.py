#!/usr/bin/env python3
"""
Linux Praktikum CTF — Telegram Bot (Reply Button UI)
Talabalar va admin uchun to'liq Reply Button interfeysi.
"""

import asyncio
import logging
import sqlite3
import subprocess
import re
import random
import os
from datetime import datetime

from telegram import (
    Update,
    ReplyKeyboardMarkup,
    KeyboardButton,
    ReplyKeyboardRemove,
)
from telegram.ext import (
    Application,
    CommandHandler,
    MessageHandler,
    ConversationHandler,
    ContextTypes,
    filters,
)

# ─── Sozlamalar ───────────────────────────────────────────────────────────────
try:
    from config import BOT_TOKEN, SERVER_IP, DB_PATH
    try:
        from config import ADMIN_IDS
    except ImportError:
        ADMIN_IDS = []
except ImportError:
    BOT_TOKEN = os.getenv("BOT_TOKEN", "YOUR_BOT_TOKEN_HERE")
    SERVER_IP = os.getenv("SERVER_IP", "auto")
    DB_PATH   = os.getenv("DB_PATH",   "/var/ctf/ctf.db")
    ADMIN_IDS = []

logging.basicConfig(format="%(asctime)s | %(levelname)s | %(message)s", level=logging.INFO)
logger = logging.getLogger(__name__)

# ─── Conversation holatlari ───────────────────────────────────────────────────
(ASK_NAME, ASK_PHONE, MAIN_MENU, WAITING_FLAG,
 ADMIN_MENU, ADMIN_WAITING_USER, ADMIN_WAITING_MSG) = range(7)

# ─── Doimiy klaviaturalar ─────────────────────────────────────────────────────
MAIN_KB = ReplyKeyboardMarkup(
    [
        ["📊 Holatim", "🏆 Reyting"],
        ["🚩 Flag yuborish"],
        ["⏹ CTF ni to'xtatish"],
    ],
    resize_keyboard=True,
    is_persistent=True,
)

ADMIN_KB = ReplyKeyboardMarkup(
    [
        ["📊 Statistika", "🏆 Top-15"],
        ["🔴 Qiynalganlar", "👤 User izlash"],
        ["📢 Xabar yuborish"],
    ],
    resize_keyboard=True,
    is_persistent=True,
)

CANCEL_KB = ReplyKeyboardMarkup([["❌ Bekor qilish"]], resize_keyboard=True)

PHONE_KB = ReplyKeyboardMarkup(
    [[KeyboardButton("📱 Telefon raqamni yuborish", request_contact=True)]],
    one_time_keyboard=True,
    resize_keyboard=True,
)

# ─── DB ───────────────────────────────────────────────────────────────────────
def get_db():
    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row
    conn.execute("PRAGMA journal_mode=WAL")
    conn.execute("PRAGMA busy_timeout=5000")
    return conn

# ─── Yordamchilar ─────────────────────────────────────────────────────────────
def get_server_ip():
    if SERVER_IP != "auto":
        return SERVER_IP
    try:
        res = subprocess.run(["hostname", "-I"], capture_output=True, text=True, timeout=3)
        ips = [ip for ip in res.stdout.strip().split()
               if not ip.startswith("127.") and not ip.startswith("172.17.")]
        return ips[0] if ips else "127.0.0.1"
    except Exception:
        return "127.0.0.1"

ADJECTIVES = ["Quick","Brave","Calm","Bold","Cool","Epic","Iron","Keen","Lean","Wild",
               "Fast","Dark","Wise","Pure","Gold","Blue","Red","Hot","Soft","Hard"]
NOUNS = ["Lion","Wolf","Bear","Eagle","Tiger","Hawk","Fox","Star","Rock","Fire",
         "Wind","Rain","Snow","Moon","Sun","Tree","Wave","Peak","Sage","Core"]

def generate_password():
    return f"{random.choice(ADJECTIVES)}{random.choice(NOUNS)}{random.randint(10,99)}"

def sanitize_username(name):
    name = name.lower().strip()
    name = re.sub(r"[^a-z0-9]", "_", name)
    name = re.sub(r"_+", "_", name).strip("_")
    return (name[:12] or "user") + "_ctf"

def unique_username(base):
    conn = get_db()
    candidate = base
    i = 2
    while conn.execute("SELECT 1 FROM telegram_users WHERE ssh_username=?", (candidate,)).fetchone():
        candidate = f"{base[:10]}_{i}"
        i += 1
    conn.close()
    return candidate

def get_user_by_tid(tid):
    conn = get_db()
    row = conn.execute("SELECT * FROM telegram_users WHERE telegram_id=?", (tid,)).fetchone()
    conn.close()
    return row

def get_progress(username):
    conn = get_db()
    p  = conn.execute("SELECT current_stage FROM progress WHERE username=?", (username,)).fetchone()
    fl = conn.execute("SELECT flag, issued_at FROM flags WHERE username=?", (username,)).fetchone()
    att = conn.execute(
        "SELECT SUM(CASE WHEN result='pass' THEN 1 ELSE 0 END) as passes,"
        " SUM(CASE WHEN result='fail' THEN 1 ELSE 0 END) as fails"
        " FROM attempts WHERE username=?", (username,)
    ).fetchone()
    conn.close()
    return p, fl, att

def is_admin(uid):
    return uid in ADMIN_IDS

# ══════════════════════════════════════════════════════════════════════════════
# /start  —  faqat talaba oqimi (admin uchun /adminkubu)
# ══════════════════════════════════════════════════════════════════════════════
async def cmd_start(update: Update, context: ContextTypes.DEFAULT_TYPE):
    tid = update.effective_user.id

    # ── Talaba: allaqachon ro'yxatdan o'tganmi? ──────────────────────────────
    row = get_user_by_tid(tid)
    if row:
        ip = get_server_ip()
        await update.message.reply_text(
            "👋 Qayta xush kelibsiz!\n\n"
            "━━━━━━━━━━━━━━━━━━\n"
            f"👤 Username: `{row['ssh_username']}`\n"
            f"🔑 Parol:    `{row['ssh_password']}`\n"
            f"🖥 IP:       `{ip}`\n"
            "━━━━━━━━━━━━━━━━━━\n\n"
            "Quyidagi menyu orqali davom eting:",
            parse_mode="Markdown",
            reply_markup=MAIN_KB,
        )
        return MAIN_MENU

    # ── Yangi talaba ─────────────────────────────────────────────────────────
    await update.message.reply_text(
        "👋 *Linux Praktikum CTF* ga xush kelibsiz!\n\n"
        "Bu platformada 10 ta amaliy Linux vazifasini\n"
        "SSH orqali yechib bilimingizni sinab ko'rasiz.\n\n"
        "Ro'yxatdan o'tish uchun *to'liq ismingizni* kiriting:",
        parse_mode="Markdown",
        reply_markup=ReplyKeyboardRemove(),
    )
    return ASK_NAME

# ══════════════════════════════════════════════════════════════════════════════
# /adminkubu  —  admin panelga kirish (faqat ADMIN_IDS da bor IDlar uchun)
# ══════════════════════════════════════════════════════════════════════════════
async def cmd_admin_login(update: Update, context: ContextTypes.DEFAULT_TYPE):
    tid = update.effective_user.id

    if not is_admin(tid):
        # Hech narsa ko'rsatmasdan, joriy holatni saqlab qaytish
        row = get_user_by_tid(tid)
        if row:
            return MAIN_MENU
        return ConversationHandler.END

    # ── Admin — statistika va panel ko'rsatish ────────────────────────────────
    conn = get_db()
    total  = conn.execute("SELECT COUNT(*) FROM progress").fetchone()[0]
    done   = conn.execute("SELECT COUNT(*) FROM flags").fetchone()[0]
    tgv    = conn.execute("SELECT COUNT(*) FROM telegram_users WHERE flag_verified=1").fetchone()[0]
    online = conn.execute(
        "SELECT COUNT(DISTINCT username) FROM ssh_activity"
        " WHERE timestamp >= datetime('now','-1 hour')"
    ).fetchone()[0]
    conn.close()
    await update.message.reply_text(
        "🔐 *Admin paneliga xush kelibsiz!*\n\n"
        "━━━━━━━━━━━━━━━━━━━━━━━\n"
        f"👥 Jami talabalar:  {total}\n"
        f"🏆 Tugatganlar:    {done}\n"
        f"📱 TG tasdiqlagan: {tgv}\n"
        f"🟢 Online (1 soat): {online}\n"
        "━━━━━━━━━━━━━━━━━━━━━━━\n\n"
        "Kerakli tugmani bosing 👇",
        parse_mode="Markdown",
        reply_markup=ADMIN_KB,
    )
    return ADMIN_MENU


# ─── Ism ─────────────────────────────────────────────────────────────────────
async def got_name(update: Update, context: ContextTypes.DEFAULT_TYPE):
    name = update.message.text.strip()
    if len(name) < 2 or len(name) > 50:
        await update.message.reply_text("❌ Ism 2–50 belgi bo'lishi kerak. Qaytadan kiriting:")
        return ASK_NAME
    context.user_data["full_name"] = name
    await update.message.reply_text(
        f"✅ Rahmat, *{name}*!\n\nTelefon raqamingizni yuboring:",
        parse_mode="Markdown",
        reply_markup=PHONE_KB,
    )
    return ASK_PHONE

# ─── Kontakt keldi ────────────────────────────────────────────────────────────
async def got_phone(update: Update, context: ContextTypes.DEFAULT_TYPE):
    contact   = update.message.contact
    tid       = update.effective_user.id
    tg_uname  = update.effective_user.username or ""
    full_name = context.user_data.get("full_name", "user")
    phone     = contact.phone_number

    existing = get_user_by_tid(tid)
    if existing:
        ip = get_server_ip()
        await update.message.reply_text(
            f"⚠️ Allaqachon ro'yxatdan o'tgansiz!\n\n"
            f"👤 `{existing['ssh_username']}`\n🔑 `{existing['ssh_password']}`\n🖥 `{ip}`",
            parse_mode="Markdown",
            reply_markup=MAIN_KB,
        )
        return MAIN_MENU

    ssh_username = unique_username(sanitize_username(full_name))
    ssh_password = generate_password()

    await update.message.reply_text("⏳ Akkaunt yaratilmoqda...", reply_markup=ReplyKeyboardRemove())

    try:
        proc = subprocess.run(
            ["sudo", "/var/ctf/setup/provision_user.sh", ssh_username],
            input=f"{ssh_password}\n",
            capture_output=True, text=True, timeout=60,
        )
        if proc.returncode != 0:
            logger.error(f"provision error: {proc.stderr}")
            await update.message.reply_text(f"❌ Texnik xato ({proc.returncode}). Admin bilan bog'laning.")
            return ConversationHandler.END
    except Exception as e:
        logger.exception(e)
        await update.message.reply_text("❌ Xato yuz berdi. Admin bilan bog'laning.")
        return ConversationHandler.END

    conn = get_db()
    conn.execute(
        "INSERT INTO telegram_users (telegram_id,telegram_username,full_name,phone,ssh_username,ssh_password)"
        " VALUES (?,?,?,?,?,?)",
        (tid, tg_uname, full_name, phone, ssh_username, ssh_password),
    )
    conn.commit()
    conn.close()

    ip = get_server_ip()
    await update.message.reply_text(
        "🎉 *Muvaffaqiyatli ro'yxatdan o'tdingiz!*\n\n"
        "━━━━━━━━━━━━━━━━━━\n"
        f"👤 Username: `{ssh_username}`\n"
        f"🔑 Parol:    `{ssh_password}`\n"
        f"🖥 IP:       `{ip}`\n"
        "━━━━━━━━━━━━━━━━━━\n\n"
        f"💻 Ulanish: `ssh {ssh_username}@{ip}`\n\n"
        "Ulangandan so'ng:\n"
        "▸ `status` — vazifani ko'rish\n"
        "▸ `check`  — javobni tekshirish\n\n"
        "Holatni quyidagi menyu orqali kuzating 👇",
        parse_mode="Markdown",
        reply_markup=MAIN_KB,
    )
    return MAIN_MENU

# ─── Telefon o'rniga matn ────────────────────────────────────────────────────
async def phone_reminder(update: Update, context: ContextTypes.DEFAULT_TYPE):
    await update.message.reply_text(
        "📱 Iltimos, kontakt tugmasini bosing:", reply_markup=PHONE_KB
    )
    return ASK_PHONE

# ══════════════════════════════════════════════════════════════════════════════
# TALABA TUGMALARI (MAIN_MENU state)
# ══════════════════════════════════════════════════════════════════════════════

async def btn_status(update: Update, context: ContextTypes.DEFAULT_TYPE):
    row = get_user_by_tid(update.effective_user.id)
    if not row:
        await update.message.reply_text("❌ Ro'yxatdan o'tmagansiz. /start bosing.")
        return ConversationHandler.END

    p, fl, att = get_progress(row["ssh_username"])
    if not p:
        await update.message.reply_text("❌ Ma'lumot topilmadi.", reply_markup=MAIN_KB)
        return MAIN_MENU

    stage  = p["current_stage"]
    passes = att["passes"] or 0 if att else 0
    fails  = att["fails"]  or 0 if att else 0

    if fl:
        done, bar, status_line = 10, "█" * 10, "🏆 Tugatdingiz!"
    else:
        done = stage - 1
        bar  = "█" * done + "░" * (10 - done)
        status_line = f"Quiz {stage}/10 da ishlayapsiz"

    lines = [
        f"📊 *Sizning holatiz*\n",
        f"👤 {row['ssh_username']}",
        f"[{bar}] {done*10}%",
        f"📍 {status_line}",
        f"\n✅ O'tgan: {passes}  ❌ Xato: {fails}",
    ]
    if fl:
        lines.append(f"\n🚩 Flagingiz:\n`{fl['flag']}`")
        lines.append("\n📱 Tasdiqlash uchun *🚩 Flag yuborish* tugmasini bosing")
    else:
        ip = get_server_ip()
        lines.append(f"\n💻 `ssh {row['ssh_username']}@{ip}`")
        lines.append("▸ `status` | `check`")

    await update.message.reply_text("\n".join(lines), parse_mode="Markdown", reply_markup=MAIN_KB)
    return MAIN_MENU

async def btn_leaderboard(update: Update, context: ContextTypes.DEFAULT_TYPE):
    conn = get_db()
    rows = conn.execute(
        "SELECT p.username, p.current_stage, f.issued_at,"
        " (SELECT COUNT(*) FROM attempts a WHERE a.username=p.username AND a.result='pass') as passes"
        " FROM progress p"
        " LEFT JOIN flags f ON p.username=f.username"
        " ORDER BY CASE WHEN f.issued_at IS NOT NULL THEN 0 ELSE 1 END,"
        " f.issued_at ASC, p.current_stage DESC, passes DESC LIMIT 15"
    ).fetchall()
    my_row = get_user_by_tid(update.effective_user.id)
    conn.close()

    medals = ["🥇", "🥈", "🥉"]
    lines = ["🏆 *REYTING (Top 15)*\n" + "━" * 22]
    for i, r in enumerate(rows, 1):
        fin = r["issued_at"] is not None
        prefix = medals[i-1] if i <= 3 and fin else f"{i:>2}."
        me = " ← siz" if my_row and r["username"] == my_row["ssh_username"] else ""
        if fin:
            t = r["issued_at"][11:16]
            lines.append(f"{prefix} `{r['username']}` 🏆({t}){me}")
        else:
            lines.append(f"{prefix} `{r['username']}` Q{r['current_stage']}/10{me}")

    if not rows:
        lines.append("📭 Hali hech kim yo'q")
    await update.message.reply_text("\n".join(lines), parse_mode="Markdown", reply_markup=MAIN_KB)
    return MAIN_MENU

async def btn_flag_start(update: Update, context: ContextTypes.DEFAULT_TYPE):
    row = get_user_by_tid(update.effective_user.id)
    if not row:
        await update.message.reply_text("❌ Avval /start bilan ro'yxatdan o'ting.")
        return MAIN_MENU

    p, fl, _ = get_progress(row["ssh_username"])

    if fl and row["flag_verified"]:
        await update.message.reply_text(
            f"✅ Flagingiz allaqachon tasdiqlangan!\n\n🚩 `{fl['flag']}`",
            parse_mode="Markdown",
            reply_markup=MAIN_KB,
        )
        return MAIN_MENU

    if not fl:
        stage = p["current_stage"] if p else 1
        await update.message.reply_text(
            f"⚠️ Siz hali Quiz {stage}/10 da ishlayapsiz.\n"
            "Flagni faqat Quiz 10 ni tugatgandan so'ng topshirishingiz mumkin.\n\n"
            "SSH da: `check` buyrug'i bilan davom eting.",
            parse_mode="Markdown",
            reply_markup=MAIN_KB,
        )
        return MAIN_MENU

    await update.message.reply_text(
        "🚩 *Flag yuborish*\n\nFlagingizni kiriting:\n`FLAG{...}` ko'rinishida\n\n"
        "Bekor qilish uchun ❌ tugmasini bosing.",
        parse_mode="Markdown",
        reply_markup=CANCEL_KB,
    )
    return WAITING_FLAG

async def got_flag(update: Update, context: ContextTypes.DEFAULT_TYPE):
    text = update.message.text.strip()
    if text == "❌ Bekor qilish":
        await update.message.reply_text("↩️ Bekor qilindi.", reply_markup=MAIN_KB)
        return MAIN_MENU

    row = get_user_by_tid(update.effective_user.id)
    if not row:
        await update.message.reply_text("❌ Xato.", reply_markup=MAIN_KB)
        return MAIN_MENU

    if not re.match(r"^(FLAG|CTF)\{[a-zA-Z0-9_-]+\}$", text):
        await update.message.reply_text(
            "❌ Noto'g'ri format!\n`FLAG{...}` ko'rinishida bo'lishi kerak.\n\n"
            "Qaytadan kiriting yoki ❌ bosib bekor qiling:",
            parse_mode="Markdown",
            reply_markup=CANCEL_KB,
        )
        return WAITING_FLAG

    conn = get_db()
    fl = conn.execute("SELECT flag FROM flags WHERE username=?", (row["ssh_username"],)).fetchone()
    if not fl:
        conn.close()
        await update.message.reply_text("⚠️ Sizda hali flag yo'q. SSH da barcha bosqichlarni bajaring.", reply_markup=MAIN_KB)
        return MAIN_MENU

    if text.upper() != fl["flag"].upper():
        conn.close()
        await update.message.reply_text(
            "❌ Noto'g'ri flag!\n\nFlagni SSH da `check` orqali oling.\nQaytadan kiriting yoki ❌:",
            parse_mode="Markdown",
            reply_markup=CANCEL_KB,
        )
        return WAITING_FLAG

    conn.execute(
        "UPDATE telegram_users SET flag_submitted=?, flag_verified=1, verified_at=CURRENT_TIMESTAMP"
        " WHERE telegram_id=?",
        (text, update.effective_user.id),
    )
    conn.commit()
    conn.close()
    logger.info(f"FLAG tasdiqlandi: {row['ssh_username']} -> {text}")

    await update.message.reply_text(
        "🎉 *TABRIKLAYMIZ!*\n\n✅ Flag to'g'ri tasdiqlandi!\n"
        f"🚩 `{text}`\n\nSiz Linux Praktikum CTF ni muvaffaqiyatli yakunladingiz! 🏆",
        parse_mode="Markdown",
        reply_markup=MAIN_KB,
    )
    return MAIN_MENU

async def btn_stop(update: Update, context: ContextTypes.DEFAULT_TYPE):
    row = get_user_by_tid(update.effective_user.id)
    if not row:
        await update.message.reply_text("Siz ro'yxatdan o'tmagansiz.", reply_markup=ReplyKeyboardRemove())
        return ConversationHandler.END

    ip = get_server_ip()
    await update.message.reply_text(
        "⏹ *CTF ni to'xtatish*\n\nSSH akkauntingiz saqlanib qoladi.\n"
        "Qaytish uchun /start bosing.\n\n"
        f"━━━━━━━━━━━━━━━━━\n"
        f"👤 `{row['ssh_username']}`\n🔑 `{row['ssh_password']}`\n🖥 `{ip}`\n"
        f"━━━━━━━━━━━━━━━━━\n\n"
        f"`ssh {row['ssh_username']}@{ip}`",
        parse_mode="Markdown",
        reply_markup=ReplyKeyboardRemove(),
    )
    return ConversationHandler.END

async def cmd_cancel(update: Update, context: ContextTypes.DEFAULT_TYPE):
    tid = update.effective_user.id
    kb = ADMIN_KB if is_admin(tid) else MAIN_KB
    await update.message.reply_text("❌ Bekor qilindi.", reply_markup=kb)
    return ADMIN_MENU if is_admin(tid) else MAIN_MENU

# ══════════════════════════════════════════════════════════════════════════════
# ADMIN TUGMALARI (ADMIN_MENU state)
# ══════════════════════════════════════════════════════════════════════════════

async def btn_admin_stats(update: Update, context: ContextTypes.DEFAULT_TYPE):
    conn = get_db()
    c = conn.cursor()
    total_progress = c.execute("SELECT COUNT(*) FROM progress").fetchone()[0]
    total_finished = c.execute("SELECT COUNT(*) FROM flags").fetchone()[0]
    tg_verified    = c.execute("SELECT COUNT(*) FROM telegram_users WHERE flag_verified=1").fetchone()[0]

    q = "SELECT COUNT(DISTINCT username) FROM ssh_activity WHERE timestamp >= datetime('now','-1 hour')"
    active_1h = c.execute(q).fetchone()[0]

    q2 = "SELECT COUNT(DISTINCT username) FROM ssh_activity WHERE timestamp >= datetime('now','-24 hours')"
    active_today = c.execute(q2).fetchone()[0]

    in_progress = c.execute(
        "SELECT COUNT(*) FROM progress WHERE current_stage>1 AND current_stage<=10"
        " AND username NOT IN (SELECT username FROM flags)"
    ).fetchone()[0]
    not_started = c.execute(
        "SELECT COUNT(*) FROM progress p WHERE p.current_stage=1"
        " AND NOT EXISTS (SELECT 1 FROM attempts a WHERE a.username=p.username)"
    ).fetchone()[0]
    total_pass = c.execute("SELECT COUNT(*) FROM attempts WHERE result='pass'").fetchone()[0]
    total_fail = c.execute("SELECT COUNT(*) FROM attempts WHERE result='fail'").fetchone()[0]
    hard_stage = c.execute(
        "SELECT stage, COUNT(*) as cnt FROM attempts WHERE result='fail' GROUP BY stage ORDER BY cnt DESC LIMIT 1"
    ).fetchone()
    avg_finish = c.execute(
        "SELECT AVG((julianday(f.issued_at)-julianday(a.fa))*24*60)"
        " FROM flags f JOIN (SELECT username,MIN(timestamp) as fa FROM attempts GROUP BY username) a"
        " ON f.username=a.username"
    ).fetchone()[0]

    stage_parts = []
    for st in range(1, 11):
        act = c.execute(
            "SELECT COUNT(*) FROM progress WHERE current_stage=?"
            " AND username NOT IN (SELECT username FROM flags)", (st,)
        ).fetchone()[0]
        if act:
            stage_parts.append(f"Q{st}:{act}")
    conn.close()

    avg_txt  = f"{avg_finish:.0f} min" if avg_finish else "—"
    hard_txt = f"Q{hard_stage['stage']} ({hard_stage['cnt']}x)" if hard_stage else "—"
    stage_txt = "  ".join(stage_parts) or "Hech kim online emas"

    await update.message.reply_text(
        "📊 *CTF STATISTIKA*\n" + "━" * 24 + "\n\n"
        f"📋 SSH talabalar: {total_progress}\n"
        f"🟢 Online (1 soat): {active_1h}\n"
        f"📅 Bugun faol: {active_today}\n\n"
        f"🏆 Tugatganlar: {total_finished}\n"
        f"📱 TG tasdiqlagan: {tg_verified}\n"
        f"⏳ Jarayonda: {in_progress}\n"
        f"⚪ Kirmagan: {not_started}\n\n"
        f"📊 Urinishlar: ✅{total_pass} ❌{total_fail}\n"
        f"🎯 Eng qiyin: {hard_txt}\n"
        f"⏱ O'rtacha: {avg_txt}\n\n"
        f"📍 Hozir qayerda:\n{stage_txt}",
        parse_mode="Markdown",
        reply_markup=ADMIN_KB,
    )
    return ADMIN_MENU

async def btn_admin_top(update: Update, context: ContextTypes.DEFAULT_TYPE):
    conn = get_db()
    rows = conn.execute(
        "SELECT p.username, p.current_stage, f.issued_at,"
        " (SELECT COUNT(*) FROM attempts a WHERE a.username=p.username AND a.result='pass') as passes,"
        " t.flag_verified"
        " FROM progress p"
        " LEFT JOIN flags f ON p.username=f.username"
        " LEFT JOIN telegram_users t ON p.username=t.ssh_username"
        " ORDER BY CASE WHEN f.issued_at IS NOT NULL THEN 0 ELSE 1 END,"
        " f.issued_at ASC, p.current_stage DESC, passes DESC LIMIT 15"
    ).fetchall()
    conn.close()

    medals = ["🥇", "🥈", "🥉"]
    lines = ["🏆 *TOP-15 LEADERBOARD*\n" + "━" * 24]
    for i, r in enumerate(rows, 1):
        fin = r["issued_at"] is not None
        tgv = "📱" if r["flag_verified"] else ""
        m = medals[i-1] if i <= 3 and fin else f"{i:>2}."
        if fin:
            t = r["issued_at"][11:16]
            lines.append(f"{m} `{r['username']}` {tgv} 🏆({t})")
        else:
            lines.append(f"{m} `{r['username']}` Q{r['current_stage']}/10")
    if not rows:
        lines.append("📭 Hali hech kim yo'q")
    await update.message.reply_text("\n".join(lines), parse_mode="Markdown", reply_markup=ADMIN_KB)
    return ADMIN_MENU

async def btn_admin_stuck(update: Update, context: ContextTypes.DEFAULT_TYPE):
    conn = get_db()
    stuck = conn.execute(
        "SELECT a.username, a.stage, COUNT(*) as fc, MIN(a.timestamp) as ft"
        " FROM attempts a JOIN progress p ON a.username=p.username"
        " WHERE a.result='fail' AND a.stage=p.current_stage"
        " GROUP BY a.username, a.stage HAVING fc>=3 ORDER BY fc DESC LIMIT 15"
    ).fetchall()
    slow = conn.execute(
        "SELECT a.username, a.stage,"
        " ROUND((julianday('now')-julianday(MIN(a.timestamp)))*24*60,0) as mins"
        " FROM attempts a JOIN progress p ON a.username=p.username"
        " WHERE a.stage=p.current_stage AND p.current_stage<=10"
        " GROUP BY a.username, a.stage HAVING mins>30 ORDER BY mins DESC LIMIT 10"
    ).fetchall()
    conn.close()

    lines = ["🔴 *Qiynalayotganlar*\n"]
    if stuck:
        lines.append("*Ko'p xato qilganlar:*")
        for r in stuck:
            try:
                mins = int((datetime.now()-datetime.fromisoformat(r["ft"])).total_seconds()//60)
                m = f" ({mins}min oldin)"
            except Exception:
                m = ""
            lines.append(f"  • `{r['username']}` — Q{r['stage']} ❌{r['fc']}{m}")
    else:
        lines.append("✅ Hech kim qiynalmayapti")
    if slow:
        lines.append("\n*30+ daqiqa sarflayotganlar:*")
        for r in slow:
            lines.append(f"  • `{r['username']}` — Q{r['stage']} ⏱{int(r['mins'])}min")
    await update.message.reply_text("\n".join(lines), parse_mode="Markdown", reply_markup=ADMIN_KB)
    return ADMIN_MENU

async def btn_admin_user_start(update: Update, context: ContextTypes.DEFAULT_TYPE):
    await update.message.reply_text("👤 Username kiriting:", reply_markup=CANCEL_KB)
    return ADMIN_WAITING_USER

async def btn_admin_user_got(update: Update, context: ContextTypes.DEFAULT_TYPE):
    text = update.message.text.strip()
    if text == "❌ Bekor qilish":
        await update.message.reply_text("↩️ Bekor qilindi.", reply_markup=ADMIN_KB)
        return ADMIN_MENU

    uname = text
    conn = get_db()
    p = conn.execute("SELECT current_stage, last_seen FROM progress WHERE username=?", (uname,)).fetchone()
    if not p:
        conn.close()
        await update.message.reply_text(f"❌ `{uname}` topilmadi.", parse_mode="Markdown", reply_markup=ADMIN_KB)
        return ADMIN_MENU

    tg = conn.execute(
        "SELECT full_name, phone, telegram_username, registered_at, last_ssh_seen, flag_verified"
        " FROM telegram_users WHERE ssh_username=?", (uname,)
    ).fetchone()
    fl = conn.execute("SELECT flag, issued_at FROM flags WHERE username=?", (uname,)).fetchone()
    sd = conn.execute(
        "SELECT stage,"
        " SUM(CASE WHEN result='pass' THEN 1 ELSE 0 END) as ps,"
        " SUM(CASE WHEN result='fail' THEN 1 ELSE 0 END) as fs,"
        " MIN(timestamp) as first,"
        " MAX(CASE WHEN result='pass' THEN timestamp END) as pa"
        " FROM attempts WHERE username=? GROUP BY stage ORDER BY stage", (uname,)
    ).fetchall()
    conn.close()

    stage = p["current_stage"]
    done = stage - 1 if stage <= 10 else 10
    bar = "█" * done + "░" * (10 - done)

    lines = [f"👤 *{uname}*\n" + "━" * 20]
    if tg:
        lines += [
            f"🗣 {tg['full_name'] or '—'}",
            f"📞 {tg['phone'] or '—'}",
            f"📅 Ro'yxat: {str(tg['registered_at'] or '')[:16]}",
            f"🖥 SSH: {str(tg['last_ssh_seen'] or '—')[:16]}",
            f"📱 TG: {'✅' if tg['flag_verified'] else '—'}",
        ]
    else:
        lines.append("📭 Telegram orqali o'tmagan")
    lines.append(f"\n[{bar}] {done*10}%  Q{stage}/10")
    if fl:
        lines.append(f"🏆 Tugadi: {str(fl['issued_at'])[:16]}\n🚩 `{fl['flag']}`")
    if sd:
        lines.append("\n📋 Bosqichlar (pass|fail|vaqt):")
        for s in sd:
            t = ""
            if s["first"] and s["pa"]:
                try:
                    mins = int((datetime.fromisoformat(s["pa"]) - datetime.fromisoformat(s["first"])).total_seconds() // 60)
                    t = f" {mins}min"
                except Exception:
                    pass
            icon = "✅" if s["ps"] > 0 else "❌"
            lines.append(f"  {icon} Q{s['stage']}: ✓{s['ps']} ✗{s['fs']}{t}")

    await update.message.reply_text("\n".join(lines), parse_mode="Markdown", reply_markup=ADMIN_KB)
    return ADMIN_MENU

async def btn_admin_broadcast_start(update: Update, context: ContextTypes.DEFAULT_TYPE):
    conn = get_db()
    count = conn.execute("SELECT COUNT(*) FROM telegram_users").fetchone()[0]
    conn.close()
    await update.message.reply_text(
        f"📢 {count} ta foydalanuvchiga yuboriladi.\nXabar matnini yozing:",
        reply_markup=CANCEL_KB,
    )
    return ADMIN_WAITING_MSG

async def btn_admin_broadcast_got(update: Update, context: ContextTypes.DEFAULT_TYPE):
    text = update.message.text.strip()
    if text == "❌ Bekor qilish":
        await update.message.reply_text("↩️ Bekor qilindi.", reply_markup=ADMIN_KB)
        return ADMIN_MENU

    conn = get_db()
    user_ids = conn.execute("SELECT telegram_id FROM telegram_users").fetchall()
    conn.close()

    sent = failed = 0
    for row in user_ids:
        try:
            await context.bot.send_message(
                chat_id=row["telegram_id"],
                text=f"📢 *Admin xabari:*\n\n{text}",
                parse_mode="Markdown",
            )
            sent += 1
            await asyncio.sleep(0.05)  # Telegram rate-limit dan saqlanish
        except Exception:
            failed += 1
    await update.message.reply_text(f"✅ Yuborildi: {sent}\n❌ Xato: {failed}", reply_markup=ADMIN_KB)
    return ADMIN_MENU

# ══════════════════════════════════════════════════════════════════════════════
# SLASH KOMANDALAR (admin uchun ham ishlaydi)
# ══════════════════════════════════════════════════════════════════════════════

async def cmd_astats(update: Update, context: ContextTypes.DEFAULT_TYPE):
    if not is_admin(update.effective_user.id):
        await update.message.reply_text("🚫 Faqat adminlar uchun.")
        return
    return await btn_admin_stats(update, context)

async def cmd_atop(update: Update, context: ContextTypes.DEFAULT_TYPE):
    if not is_admin(update.effective_user.id):
        await update.message.reply_text("🚫 Faqat adminlar uchun.")
        return
    return await btn_admin_top(update, context)

async def cmd_astuck(update: Update, context: ContextTypes.DEFAULT_TYPE):
    if not is_admin(update.effective_user.id):
        await update.message.reply_text("🚫 Faqat adminlar uchun.")
        return
    return await btn_admin_stuck(update, context)

async def cmd_auser(update: Update, context: ContextTypes.DEFAULT_TYPE):
    if not is_admin(update.effective_user.id):
        await update.message.reply_text("🚫 Faqat adminlar uchun.")
        return
    if context.args:
        context.user_data["_tmp_search"] = context.args[0]
        update.message.text = context.args[0]
        return await btn_admin_user_got(update, context)
    await update.message.reply_text("Foydalanish: `/auser <username>`", parse_mode="Markdown")

async def cmd_abroadcast(update: Update, context: ContextTypes.DEFAULT_TYPE):
    if not is_admin(update.effective_user.id):
        await update.message.reply_text("🚫 Faqat adminlar uchun.")
        return
    msg = " ".join(context.args).strip()
    if not msg:
        await update.message.reply_text("Foydalanish: `/abroadcast <xabar>`", parse_mode="Markdown")
        return
    conn = get_db()
    user_ids = conn.execute("SELECT telegram_id FROM telegram_users").fetchall()
    conn.close()
    sent = failed = 0
    for row in user_ids:
        try:
            await context.bot.send_message(chat_id=row["telegram_id"], text=f"📢 *Admin:*\n\n{msg}", parse_mode="Markdown")
            sent += 1
            await asyncio.sleep(0.05)  # Telegram rate-limit dan saqlanish
        except Exception:
            failed += 1
    await update.message.reply_text(f"✅ Yuborildi: {sent}\n❌ Xato: {failed}")

async def cmd_ahelp(update: Update, context: ContextTypes.DEFAULT_TYPE):
    if not is_admin(update.effective_user.id):
        await update.message.reply_text("🚫 Faqat adminlar uchun.")
        return
    await update.message.reply_text(
        "🔐 *Admin buyruqlar:*\n\n"
        "`/adminkubu` — Admin panelga kirish\n"
        "`/astats` — Statistika\n"
        "`/atop` — Leaderboard\n"
        "`/astuck` — Qiynalayotganlar\n"
        "`/auser <username>` — User tafsiloti\n"
        "`/abroadcast <xabar>` — Hammaga xabar\n"
        "`/ahelp` — Yordam",
        parse_mode="Markdown",
        reply_markup=ADMIN_KB,
    )

# ─── Main ─────────────────────────────────────────────────────────────────────
def main():
    app = Application.builder().token(BOT_TOKEN).build()

    conv = ConversationHandler(
        entry_points=[
            CommandHandler("start",      cmd_start),
            CommandHandler("adminkubu",  cmd_admin_login),  # Admin panel kirish
        ],
        states={
            ASK_NAME: [
                MessageHandler(filters.TEXT & ~filters.COMMAND, got_name),
            ],
            ASK_PHONE: [
                MessageHandler(filters.CONTACT, got_phone),
                MessageHandler(filters.TEXT & ~filters.COMMAND, phone_reminder),
            ],
            # ── Talaba menyu ─────────────────────────────────────────────────
            MAIN_MENU: [
                MessageHandler(filters.Regex(r"^📊 Holatim$"),           btn_status),
                MessageHandler(filters.Regex(r"^🏆 Reyting$"),           btn_leaderboard),
                MessageHandler(filters.Regex(r"^🚩 Flag yuborish$"),      btn_flag_start),
                MessageHandler(filters.Regex(r"^⏹ CTF ni to'xtatish$"), btn_stop),
                CommandHandler("adminkubu",  cmd_admin_login),
                CommandHandler("cancel",     cmd_cancel),
            ],
            WAITING_FLAG: [
                MessageHandler(filters.TEXT & ~filters.COMMAND, got_flag),
                CommandHandler("adminkubu",  cmd_admin_login),
            ],
            # ── Admin menyu ──────────────────────────────────────────────────
            ADMIN_MENU: [
                MessageHandler(filters.Regex(r"^📊 Statistika$"),      btn_admin_stats),
                MessageHandler(filters.Regex(r"^🏆 Top-15$"),          btn_admin_top),
                MessageHandler(filters.Regex(r"^🔴 Qiynalganlar$"),    btn_admin_stuck),
                MessageHandler(filters.Regex(r"^👤 User izlash$"),      btn_admin_user_start),
                MessageHandler(filters.Regex(r"^📢 Xabar yuborish$"),  btn_admin_broadcast_start),
                CommandHandler("adminkubu",  cmd_admin_login),
                CommandHandler("cancel",     cmd_cancel),
            ],
            ADMIN_WAITING_USER: [
                MessageHandler(filters.TEXT & ~filters.COMMAND, btn_admin_user_got),
                CommandHandler("adminkubu",  cmd_admin_login),
            ],
            ADMIN_WAITING_MSG: [
                MessageHandler(filters.TEXT & ~filters.COMMAND, btn_admin_broadcast_got),
                CommandHandler("adminkubu",  cmd_admin_login),
            ],
        },
        fallbacks=[
            CommandHandler("cancel",    cmd_cancel),
            CommandHandler("adminkubu", cmd_admin_login),  # Har qanday holatda ishlaydi
        ],
        allow_reentry=True,
    )

    app.add_handler(conv)

    # Slash komandalar (ham ishlaydi)
    app.add_handler(CommandHandler("astats",     cmd_astats))
    app.add_handler(CommandHandler("atop",       cmd_atop))
    app.add_handler(CommandHandler("astuck",     cmd_astuck))
    app.add_handler(CommandHandler("auser",      cmd_auser))
    app.add_handler(CommandHandler("abroadcast", cmd_abroadcast))
    app.add_handler(CommandHandler("ahelp",      cmd_ahelp))

    logger.info("🤖 CTF Bot ishga tushdi (Button UI + Admin Panel)...")
    app.run_polling(drop_pending_updates=True)

if __name__ == "__main__":
    main()
