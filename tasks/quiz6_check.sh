#!/bin/bash
# quiz6_check.sh <username> [flag]
U=$1
GIVEN=$2

VAULT_FILE="/home/$U/quiz6/backup_storage/db/archive/.vault_key.dat"

# Fayl mavjudligi va unga o'qish ruxsati berilganligi (chmod/chown)
if [ ! -f "$VAULT_FILE" ]; then
    exit 1
fi

if [ -z "$GIVEN" ]; then
    if [ -f "/home/$U/quiz6/flag.txt" ] && [ ! -L "/home/$U/quiz6/flag.txt" ]; then
        GIVEN=$(head -c 120 "/home/$U/quiz6/flag.txt" | tr -d '[:space:]')
    elif [ -f "/home/$U/quiz6/answer.txt" ] && [ ! -L "/home/$U/quiz6/answer.txt" ]; then
        GIVEN=$(head -c 120 "/home/$U/quiz6/answer.txt" | tr -d '[:space:]')
    fi
fi

EXPECTED=$(sqlite3 -cmd ".timeout 5000" /var/ctf/ctf.db "SELECT expected FROM answers WHERE username='$U' AND stage=6;" 2>/dev/null)

if [ -n "$EXPECTED" ] && [ "$GIVEN" = "$EXPECTED" ]; then
    exit 0
fi
exit 1
