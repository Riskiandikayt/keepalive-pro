#!/data/data/com.termux/files/usr/bin/bash
# ============================================================
#  TERMUX:BOOT — Auto start Keepalive saat HP restart
#  Letakkan file ini di: ~/.termux/boot/keepalive-boot.sh
# ============================================================

# Tunggu sistem siap
sleep 10

# Start keepalive
KEEPALIVE_DIR="$HOME/keepalive-pro"

if [[ -f "$KEEPALIVE_DIR/keepalive" ]]; then
    cd "$KEEPALIVE_DIR"
    bash "$KEEPALIVE_DIR/keepalive" start
fi
