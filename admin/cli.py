#!/usr/bin/env python3
"""
admin/cli.py — Linux CTF Terminal Live Dashboard
O'qituvchi va hakamlar uchun terminalda jonli monitoring.

Foydalanish:
  python3 cli.py          # Jonli yangilanuvchi rejim (Ctrl+C bilan chiqish)
  python3 cli.py --once   # Bir marta chiqarib chiqish
"""

import sys
import os
import time
import sqlite3
import subprocess
import argparse
from datetime import datetime

RESET   = "\033[0m"
BOLD    = "\033[1m"
DIM     = "\033[2m"
RED     = "\033[31m"
GREEN   = "\033[32m"
YELLOW  = "\033[33m"
BLUE    = "\033[34m"
MAGENTA = "\033[35m"
CYAN    = "\033[36m"
WHITE   = "\033[37m"

TOTAL_STAGES = 10

def find_db_path():
    paths = [
        "/var/ctf/ctf.db",
        os.path.join(os.path.dirname(os.path.abspath(__file__)), "../ctf.db"),
    ]
    for p in paths:
        if os.path.exists(p):
            return p
    return "/var/ctf/ctf.db"

def get_online_users(db_path=None):
    users = set()
    try:
        res = subprocess.run(["who"], capture_output=True, text=True, timeout=2)
        for line in res.stdout.strip().splitlines():
            parts = line.split()
            if parts:
                users.add(parts[0])
    except Exception:
        pass

    if db_path and os.path.exists(db_path):
        try:
            conn = sqlite3.connect(db_path, timeout=3.0)
            rows = conn.execute(
                "SELECT DISTINCT username FROM ssh_activity "
                "WHERE timestamp >= datetime('now','-5 minutes')"
            ).fetchall()
            conn.close()
            for r in rows:
                users.add(r[0])
        except Exception:
            pass
    return users

def fetch_data(db_path):
    if not os.path.exists(db_path):
        return []
    try:
        conn = sqlite3.connect(db_path, timeout=4.0)
        conn.row_factory = sqlite3.Row
        cur = conn.cursor()

        cur.execute("""
            SELECT p.username, p.current_stage, p.updated_at, p.last_seen,
                   f.flag AS final_flag
            FROM progress p
            LEFT JOIN flags f ON p.username = f.username
            ORDER BY 
                CASE WHEN p.current_stage > 10 THEN 0 ELSE 1 END,
                p.current_stage DESC, 
                p.updated_at ASC
        """)
        rows = cur.fetchall()

        # Solved stages
        solved_map = {}
        for r in cur.execute("SELECT username, stage FROM solved_stages"):
            u, st = r[0], r[1]
            if u not in solved_map:
                solved_map[u] = set()
            solved_map[u].add(st)

        # Attempts
        stats = {}
        for r in cur.execute("SELECT username, result, COUNT(*) FROM attempts GROUP BY username, result"):
            u, res, c = r[0], r[1], r[2]
            if u not in stats:
                stats[u] = {"pass": 0, "fail": 0}
            stats[u][res] = c

        conn.close()

        result = []
        for r in rows:
            u = r["username"]
            st = stats.get(u, {"pass": 0, "fail": 0})
            sol = solved_map.get(u, set())
            result.append({
                "username": u,
                "stage": r["current_stage"],
                "updated_at": r["updated_at"] or "",
                "last_seen": r["last_seen"] or "",
                "final_flag": r["final_flag"] or "",
                "pass_count": st["pass"],
                "fail_count": st["fail"],
                "solved": sol,
            })
        return result
    except Exception as e:
        return []

def render_dashboard(db_path):
    data = fetch_data(db_path)
    online_users = get_online_users(db_path)

    total_students = len(data)
    finished = sum(1 for d in data if d["stage"] > TOTAL_STAGES)
    in_progress = total_students - finished
    online_count = sum(1 for d in data if d["username"] in online_users)

    now_str = datetime.now().strftime("%Y-%m-%d %H:%M:%S")

    out = []
    out.append(f"{BOLD}{CYAN}╔════════════════════════════════════════════════════════════════════════════════════════════════════════╗{RESET}")
    out.append(f"{BOLD}{CYAN}║{RESET}  {BOLD}🚩 LINUX CTF — MONITORING DASHBOARD{RESET}                                      {DIM}{now_str}{RESET}   {BOLD}{CYAN}║{RESET}")
    out.append(f"{BOLD}{CYAN}╠════════════════════════════════════════════════════════════════════════════════════════════════════════╣{RESET}")
    out.append(f"{BOLD}{CYAN}║{RESET}  Talabalar: {BOLD}{total_students}{RESET}  │  🟢 Online: {GREEN}{BOLD}{online_count}{RESET}  │  🏃 Jarayonda: {YELLOW}{in_progress}{RESET}  │  🏆 Tugatganlar: {GREEN}{BOLD}{finished}{RESET}               {BOLD}{CYAN}║{RESET}")
    out.append(f"{BOLD}{CYAN}╠════════════════════════════════════════════════════════════════════════════════════════════════════════╣{RESET}")
    out.append(f"{BOLD}{CYAN}║{RESET}  {BOLD}{'Foydalanuvchi':<16} {'Bosqich':<10} {'Flaglar (1..10)':<22} {'Urinishlar':<12} {'Holat':<12} {'Oxirgi faollik':<18}{RESET} {BOLD}{CYAN}║{RESET}")
    out.append(f"{BOLD}{CYAN}╠════════════════════════════════════════════════════════════════════════════════════════════════════════╣{RESET}")

    if not data:
        out.append(f"{BOLD}{CYAN}║{RESET}  {DIM}Hozircha ro'yxatdan o'tgan talabalar yo'q...{RESET}                                                   {BOLD}{CYAN}║{RESET}")
    else:
        for idx, d in enumerate(data, 1):
            u = d["username"]
            is_online = u in online_users
            st = d["stage"]

            # Online dot
            dot = f"{GREEN}●{RESET}" if is_online else f"{DIM}○{RESET}"

            # Stage representation
            if st > TOTAL_STAGES:
                stage_str = f"{GREEN}{BOLD}DONE (10){RESET}"
            else:
                stage_str = f"Quiz {st}/10"

            # Matrix 1..10
            mat_parts = []
            for q in range(1, TOTAL_STAGES + 1):
                if q in d["solved"] or st > q:
                    mat_parts.append(f"{GREEN}■{RESET}")
                elif q == st:
                    mat_parts.append(f"{YELLOW}▶{RESET}")
                else:
                    mat_parts.append(f"{DIM}·{RESET}")
            matrix_str = " ".join(mat_parts)

            att_str = f"{GREEN}✓{d['pass_count']}{RESET} {RED}✗{d['fail_count']}{RESET}"
            status_str = f"{GREEN}Online{RESET} " if is_online else f"{DIM}Offline{RESET}"
            time_str = d["last_seen"][-8:] if d["last_seen"] else (d["updated_at"][-8:] if d["updated_at"] else "-")

            out.append(f"{BOLD}{CYAN}║{RESET} {dot} {u:<14} {stage_str:<19} {matrix_str:<40} {att_str:<20} {status_str:<18} {time_str:<18} {BOLD}{CYAN}║{RESET}")

    out.append(f"{BOLD}{CYAN}╚════════════════════════════════════════════════════════════════════════════════════════════════════════╝{RESET}")
    out.append(f"{DIM} Yangilanish: 2 soniya. Chiqish uchun: Ctrl+C{RESET}")
    return "\n".join(out)

def main():
    parser = argparse.ArgumentParser(description="CTF Live Dashboard")
    parser.add_argument("--once", action="store_true", help="Faqat bir marta ko'rsatib chiqish")
    parser.add_argument("--db", default=None, help="Baza fayli yo'li")
    args = parser.parse_args()

    db_path = args.db or find_db_path()

    if args.once:
        print(render_dashboard(db_path))
        return

    try:
        while True:
            os.system("clear")
            print(render_dashboard(db_path))
            time.sleep(2)
    except KeyboardInterrupt:
        print(f"\n{GREEN}Monitoring yakunlandi.{RESET}")

if __name__ == "__main__":
    main()
