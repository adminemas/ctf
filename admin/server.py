#!/usr/bin/env python3
"""
admin/server.py — Linux CTF Web Dashboard Server
O'qituvchi va hakamlar uchun chiroyli Real-time Web Dashboard (pure Python, pip talab qilmaydi).

Foydalanish:
  python3 server.py             # Port 8080 da ishga tushadi
  python3 server.py --port 8000 # Maxsus port
  python3 server.py --daemon    # Orqa fonda ishga tushirish
  python3 server.py stop        # Orqa fondagini to'xtatish
"""

import sys, os, time, json, sqlite3, subprocess, argparse, base64
from datetime import datetime
from http.server import ThreadingHTTPServer, BaseHTTPRequestHandler

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from cli import fetch_data, find_db_path, get_online_users

PID_FILE = "/var/ctf/web_dashboard.pid"
CRED_FILE = "/var/ctf/admin.cred"
TOTAL_STAGES = 10

HTML_PAGE = """<!DOCTYPE html>
<html lang="uz">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>🚩 Linux CTF — Jonli Admin Panel</title>
    <link href="https://fonts.googleapis.com/css2?family=Fira+Code:wght@400;600&family=Inter:wght@400;600;700;800&display=swap" rel="stylesheet">
    <style>
        :root {
            --bg-base:    #0B0F19;
            --bg-surface: #111827;
            --bg-card:    #1F2937;
            --border:     #374151;
            --text:       #F9FAFB;
            --muted:      #9CA3AF;
            --green:      #10B981;
            --blue:       #3B82F6;
            --yellow:     #F59E0B;
            --red:        #EF4444;
            --purple:     #8B5CF6;
        }
        *, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }
        body {
            font-family: 'Inter', sans-serif;
            background: var(--bg-base);
            color: var(--text);
            min-height: 100vh;
            padding: 24px;
        }
        .container { max-width: 1400px; margin: 0 auto; display: flex; flex-direction: column; gap: 24px; }
        .header {
            display: flex; justify-content: space-between; align-items: center;
            background: var(--bg-surface); padding: 20px 24px; border-radius: 12px;
            border: 1px solid var(--border);
        }
        .header h1 { font-size: 1.5rem; font-weight: 800; display: flex; align-items: center; gap: 10px; }
        .stats-grid {
            display: grid; grid-template-columns: repeat(auto-fit, minmax(220px, 1fr)); gap: 16px;
        }
        .stat-card {
            background: var(--bg-surface); padding: 20px; border-radius: 12px;
            border: 1px solid var(--border); display: flex; flex-direction: column; gap: 8px;
        }
        .stat-card .val { font-size: 2rem; font-weight: 800; }
        .stat-card .lbl { font-size: 0.85rem; color: var(--muted); text-transform: uppercase; letter-spacing: 0.05em; }
        .table-card {
            background: var(--bg-surface); border-radius: 12px; border: 1px solid var(--border);
            overflow: hidden;
        }
        table { width: 100%; border-collapse: collapse; text-align: left; }
        th {
            background: var(--bg-card); padding: 14px 18px; font-size: 0.8rem;
            text-transform: uppercase; color: var(--muted); letter-spacing: 0.05em;
        }
        td { padding: 14px 18px; border-bottom: 1px solid rgba(255,255,255,0.05); font-size: 0.95rem; }
        tr:hover td { background: rgba(255,255,255,0.02); }
        .mono { font-family: 'Fira Code', monospace; }
        .badge {
            padding: 4px 10px; border-radius: 6px; font-size: 0.8rem; font-weight: 600; display: inline-block;
        }
        .badge-green { background: rgba(16,185,129,0.15); color: var(--green); }
        .badge-yellow { background: rgba(245,158,11,0.15); color: var(--yellow); }
        .badge-red { background: rgba(239,68,68,0.15); color: var(--red); }
        .quiz-dots { display: flex; gap: 6px; }
        .quiz-dot {
            width: 22px; height: 22px; border-radius: 4px; display: flex; align-items: center;
            justify-content: center; font-size: 0.75rem; font-weight: 700; font-family: 'Fira Code', monospace;
        }
        .dot-done { background: var(--green); color: #000; }
        .dot-curr { background: var(--yellow); color: #000; animation: pulse 1.5s infinite; }
        .dot-lock { background: var(--bg-card); color: var(--muted); border: 1px solid var(--border); }
        @keyframes pulse { 0%, 100% { opacity: 1; } 50% { opacity: 0.4; } }
        .online-tag { display: inline-flex; align-items: center; gap: 6px; font-size: 0.85rem; }
        .online-dot { width: 8px; height: 8px; border-radius: 50%; }
        .dot-on { background: var(--green); box-shadow: 0 0 8px var(--green); }
        .dot-off { background: var(--muted); }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>🚩 Linux Praktikum CTF — Boshqaruv Paneli</h1>
            <div style="font-size: 0.9rem; color: var(--muted);" id="time-display">--:--:--</div>
        </div>

        <div class="stats-grid">
            <div class="stat-card">
                <div class="lbl">Jami Talabalar</div>
                <div class="val" id="stat-total">0</div>
            </div>
            <div class="stat-card">
                <div class="lbl">Online Talabalar</div>
                <div class="val" style="color: var(--green);" id="stat-online">0</div>
            </div>
            <div class="stat-card">
                <div class="lbl">Jarayondagilar</div>
                <div class="val" style="color: var(--yellow);" id="stat-active">0</div>
            </div>
            <div class="stat-card">
                <div class="lbl">Tugatganlar (10/10)</div>
                <div class="val" style="color: var(--purple);" id="stat-done">0</div>
            </div>
        </div>

        <div class="table-card">
            <table>
                <thead>
                    <tr>
                        <th>#</th>
                        <th>Talaba</th>
                        <th>Holat</th>
                        <th>Bosqich</th>
                        <th>Quizlar Matrixi (1..10)</th>
                        <th>Urinishlar</th>
                        <th>Oxirgi Faollik</th>
                    </tr>
                </thead>
                <tbody id="students-tbody">
                    <tr><td colspan="7" style="text-align: center; color: var(--muted);">Ma'lumotlar yuklanmoqda...</td></tr>
                </tbody>
            </table>
        </div>
    </div>

    <script>
        async function updateDashboard() {
            try {
                const res = await fetch('/api/data');
                if (!res.ok) return;
                const data = await res.json();

                document.getElementById('time-display').textContent = data.timestamp;
                document.getElementById('stat-total').textContent = data.total;
                document.getElementById('stat-online').textContent = data.online;
                document.getElementById('stat-active').textContent = data.active;
                document.getElementById('stat-done').textContent = data.done;

                const tbody = document.getElementById('students-tbody');
                if (data.students.length === 0) {
                    tbody.innerHTML = '<tr><td colspan="7" style="text-align:center; color: var(--muted);">Hozircha talabalar yoq</td></tr>';
                    return;
                }

                let html = '';
                data.students.forEach((s, idx) => {
                    let dots = '';
                    for (let q = 1; q <= 10; q++) {
                        if (s.solved.includes(q) || s.stage > q) {
                            dots += `<div class="quiz-dot dot-done" title="Quiz ${q}: Bajarilgan">✓</div>`;
                        } else if (s.stage === q) {
                            dots += `<div class="quiz-dot dot-curr" title="Quiz ${q}: Hozirgi">${q}</div>`;
                        } else {
                            dots += `<div class="quiz-dot dot-lock" title="Quiz ${q}: Qulflangan">·</div>`;
                        }
                    }

                    const onClass = s.is_online ? 'dot-on' : 'dot-off';
                    const onText = s.is_online ? '<span style="color:var(--green)">Online</span>' : '<span style="color:var(--muted)">Offline</span>';

                    let stageBadge = `<span class="badge badge-yellow">Quiz ${s.stage}/10</span>`;
                    if (s.stage > 10) {
                        stageBadge = `<span class="badge badge-green">🏆 G'OLIB</span>`;
                    }

                    html += `<tr>
                        <td style="color:var(--muted);">${idx + 1}</td>
                        <td class="mono" style="font-weight:700;">${s.username}</td>
                        <td><div class="online-tag"><span class="online-dot ${onClass}"></span> ${onText}</div></td>
                        <td>${stageBadge}</td>
                        <td><div class="quiz-dots">${dots}</div></td>
                        <td><span style="color:var(--green)">✓${s.pass_count}</span> <span style="color:var(--red)">✗${s.fail_count}</span></td>
                        <td class="mono" style="font-size:0.85rem; color:var(--muted);">${s.last_seen || s.updated_at || '-'}</td>
                    </tr>`;
                });
                tbody.innerHTML = html;
            } catch (err) {
                console.error(err);
            }
        }
        setInterval(updateDashboard, 2000);
        updateDashboard();
    </script>
</body>
</html>
"""

class CTFRequestHandler(BaseHTTPRequestHandler):
    def check_auth(self):
        if not os.path.exists(CRED_FILE):
            return True
        with open(CRED_FILE, "r") as f:
            valid = f.read().strip()
        auth_header = self.headers.get("Authorization")
        if not auth_header or not auth_header.startswith("Basic "):
            return False
        try:
            encoded = auth_header.split(" ", 1)[1]
            decoded = base64.b64decode(encoded).decode("utf-8")
            return decoded == valid
        except Exception:
            return False

    def do_GET(self):
        if not self.check_auth():
            self.send_response(401)
            self.send_header("WWW-Authenticate", 'Basic realm="CTF Admin Dashboard"')
            self.end_headers()
            self.wfile.write(b"Autentifikatsiya talab qilinadi.")
            return

        if self.path == "/" or self.path == "/index.html":
            self.send_response(200)
            self.send_header("Content-Type", "text/html; charset=utf-8")
            self.end_headers()
            self.wfile.write(HTML_PAGE.encode("utf-8"))
            return

        if self.path == "/api/data":
            db_path = find_db_path()
            raw_data = fetch_data(db_path)
            online_users = get_online_users(db_path)

            students = []
            for d in raw_data:
                students.append({
                    "username": d["username"],
                    "stage": d["stage"],
                    "updated_at": d["updated_at"],
                    "last_seen": d["last_seen"],
                    "pass_count": d["pass_count"],
                    "fail_count": d["fail_count"],
                    "solved": list(d["solved"]),
                    "is_online": d["username"] in online_users,
                })

            total = len(students)
            done = sum(1 for s in students if s["stage"] > TOTAL_STAGES)
            active = total - done
            online = sum(1 for s in students if s["is_online"])

            payload = {
                "timestamp": datetime.now().strftime("%Y-%m-%d %H:%M:%S"),
                "total": total,
                "online": online,
                "active": active,
                "done": done,
                "students": students,
            }

            self.send_response(200)
            self.send_header("Content-Type", "application/json")
            self.send_header("Cache-Control", "no-cache")
            self.end_headers()
            self.wfile.write(json.dumps(payload).encode("utf-8"))
            return

        self.send_response(404)
        self.end_headers()

def main():
    parser = argparse.ArgumentParser(description="CTF Web Dashboard")
    parser.add_argument("--port", type=int, default=8080, help="Web server porti (default: 8080)")
    parser.add_argument("--daemon", action="store_true", help="Daemon rejimida orqa fonda ishga tushirish")
    parser.add_argument("action", nargs="?", default="start", choices=["start", "stop", "status"], help="Boshqarish buyrug'i")
    args = parser.parse_args()

    if args.action == "stop":
        if os.path.exists(PID_FILE):
            try:
                with open(PID_FILE, "r") as f:
                    pid = int(f.read().strip())
                os.kill(pid, 15)
                os.remove(PID_FILE)
                print("✅ CTF Web Dashboard to'xtatildi.")
            except Exception as e:
                print(f"❌ Xato: {e}")
        else:
            print("⚠️ CTF Web Dashboard ishlamayapti.")
        return

    if args.daemon:
        # Daemonize
        pid = os.fork()
        if pid > 0:
            print(f"🚀 Web Dashboard fonda ishga tushirildi (PID: {pid}). Port: {args.port}")
            with open(PID_FILE, "w") as f:
                f.write(str(pid))
            sys.exit(0)
        os.setsid()

    server = ThreadingHTTPServer(("0.0.0.0", args.port), CTFRequestHandler)
    print(f"🌐 CTF Web Dashboard serveri ishga tushdi: http://0.0.0.0:{args.port}")
    if os.path.exists(CRED_FILE):
        with open(CRED_FILE, "r") as f:
            print(f"🔑 Kirish: {f.read().strip()}")
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("\nServer to'xtatildi.")

if __name__ == "__main__":
    main()
