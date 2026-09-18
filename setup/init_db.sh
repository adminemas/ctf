#!/bin/bash
# /var/ctf/setup/init_db.sh
# CTF SQLite bazasini va asosiy kataloglarni yaratadi.

set -e

mkdir -p /var/ctf/tasks /var/ctf/setup /var/ctf/admin /var/ctf/bot
chmod 700 /var/ctf

if [ ! -f /var/ctf/secret.key ]; then
    openssl rand -hex 32 > /var/ctf/secret.key
    chmod 600 /var/ctf/secret.key
    chown root:root /var/ctf/secret.key
    echo "[+] Yangi secret.key yaratildi."
fi

if [ -L /var/ctf/ctf.db ]; then
    rm -f /var/ctf/ctf.db
fi

sqlite3 /var/ctf/ctf.db <<'EOF'
PRAGMA journal_mode=WAL;
PRAGMA busy_timeout=5000;

CREATE TABLE IF NOT EXISTS progress (
    username      TEXT PRIMARY KEY,
    current_stage INTEGER DEFAULT 1,
    updated_at    DATETIME DEFAULT CURRENT_TIMESTAMP,
    last_seen     DATETIME
);

CREATE TABLE IF NOT EXISTS attempts (
    id         INTEGER PRIMARY KEY AUTOINCREMENT,
    username   TEXT,
    stage      INTEGER,
    flag_given TEXT,
    result     TEXT CHECK(result IN ('pass','fail')),
    timestamp  DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- Har bir quiz uchun topilgan flaglar
CREATE TABLE IF NOT EXISTS solved_stages (
    username     TEXT,
    stage        INTEGER,
    flag         TEXT,
    completed_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (username, stage)
);

-- Yakuniy umumiy flag (10-bosqich yakunida)
CREATE TABLE IF NOT EXISTS flags (
    username  TEXT PRIMARY KEY,
    flag      TEXT,
    issued_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- Har bir talabaning har bir quizidagi kutilgan maxfiy flagi
CREATE TABLE IF NOT EXISTS answers (
    username TEXT,
    stage    INTEGER,
    expected TEXT,
    PRIMARY KEY (username, stage)
);

-- SSH faollik monitoringi
CREATE TABLE IF NOT EXISTS ssh_activity (
    id        INTEGER PRIMARY KEY AUTOINCREMENT,
    username  TEXT,
    action    TEXT,
    stage     INTEGER,
    timestamp DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- Telegram orqali ro'yxatdan o'tganlar (agar bot ishlatilsa)
CREATE TABLE IF NOT EXISTS telegram_users (
    telegram_id       INTEGER PRIMARY KEY,
    telegram_username TEXT,
    full_name         TEXT,
    phone             TEXT,
    ssh_username      TEXT UNIQUE,
    ssh_password      TEXT,
    registered_at     DATETIME DEFAULT CURRENT_TIMESTAMP,
    last_ssh_seen     DATETIME,
    flag_submitted    TEXT,
    flag_verified     INTEGER DEFAULT 0,
    verified_at       DATETIME
);

-- Indekslar
CREATE INDEX IF NOT EXISTS idx_attempts_username ON attempts(username);
CREATE INDEX IF NOT EXISTS idx_attempts_stage ON attempts(stage);
CREATE INDEX IF NOT EXISTS idx_solved_user ON solved_stages(username);
CREATE INDEX IF NOT EXISTS idx_ssh_activity_username ON ssh_activity(username);
CREATE INDEX IF NOT EXISTS idx_telegram_users_ssh ON telegram_users(ssh_username);
EOF

chmod 600 /var/ctf/ctf.db
chown root:root /var/ctf/ctf.db

echo "[+] SQLite baza tayyor: /var/ctf/ctf.db"
