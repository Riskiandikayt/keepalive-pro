#!/data/data/com.termux/files/usr/bin/bash
# ============================================================
#  KEEPALIVE CONFIG — Edit di sini atau pakai CLI
# ============================================================

WEBSITES=(
    "https://example.com"
)

REFRESH_INTERVAL=240       # detik (240 = 4 menit, aman untuk Replit)
REQUEST_TIMEOUT=10
RETRY_WAIT=5
REQUEST_METHOD="GET"

ENABLE_LOG=true
ENABLE_NOTIFICATION=true
ENABLE_DASHBOARD=true
ENABLE_BROWSER=false       # curl only, tidak buka browser

LOG_FILE="$(dirname "$0")/logs.txt"
PID_FILE="$(dirname "$0")/.keepalive.pid"
LOCK_FILE="$(dirname "$0")/.keepalive.lock"
MAX_LOG_LINES=500
