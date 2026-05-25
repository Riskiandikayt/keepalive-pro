#!/data/data/com.termux/files/usr/bin/bash
# ============================================================
#  KEEPALIVE CONFIG — Edit di sini atau pakai CLI
# ============================================================

WEBSITES=(
    "https://3051aebb-5af9-4222-be20-c50d75cce2c5-00-1leu8elbz899h.janeway.replit.dev/"
)

REFRESH_INTERVAL=240
REQUEST_TIMEOUT=10
RETRY_WAIT=5
REQUEST_METHOD="GET"

ENABLE_LOG=true
ENABLE_NOTIFICATION=true
ENABLE_DASHBOARD=true
ENABLE_BROWSER=false

LOG_FILE="$(dirname "$0")/logs.txt"
PID_FILE="$(dirname "$0")/.keepalive.pid"
LOCK_FILE="$(dirname "$0")/.keepalive.lock"
MAX_LOG_LINES=500
EOF
