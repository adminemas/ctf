#!/bin/bash
# quiz5_check.sh <username> [flag]
U=$1
GIVEN=$2

if [ -z "$GIVEN" ]; then
    if [ -f "/home/$U/quiz5/flag.txt" ] && [ ! -L "/home/$U/quiz5/flag.txt" ]; then
        GIVEN=$(head -c 120 "/home/$U/quiz5/flag.txt" | tr -d '[:space:]')
    elif [ -f "/home/$U/quiz5/answer.txt" ] && [ ! -L "/home/$U/quiz5/answer.txt" ]; then
        GIVEN=$(head -c 120 "/home/$U/quiz5/answer.txt" | tr -d '[:space:]')
    fi
fi

EXPECTED=$(sqlite3 -cmd ".timeout 5000" /var/ctf/ctf.db "SELECT expected FROM answers WHERE username='$U' AND stage=5;" 2>/dev/null)

if [ -n "$EXPECTED" ] && [ "$GIVEN" = "$EXPECTED" ]; then
    exit 0
fi
exit 1
