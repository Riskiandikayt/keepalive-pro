#!/data/data/com.termux/files/usr/bin/bash
# ============================================================
#  KEEPALIVE MAIN — curl reload, no browser, 24/7
# ============================================================

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/config.sh"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; CYAN='\033[0;36m'; MAGENTA='\033[0;35m'
WHITE='\033[1;37m'; DIM='\033[2m'; RESET='\033[0m'; BOLD='\033[1m'

START_TIME=$(date +%s)
declare -A TOTAL_RELOAD LAST_STATUS LAST_RESPONSE_TIME PREV_STATUS
declare -A RELOAD_SUCCESS RELOAD_FAIL
LAST_RELOAD_TIME="–"
INTERNET_STATUS="Unknown"
NEXT_RELOAD=0
TOTAL_UPTIME_RELOAD=0

init() {
    echo "$$" > "$PID_FILE"
    touch "$LOG_FILE"
    for url in "${WEBSITES[@]}"; do
        TOTAL_RELOAD["$url"]=0
        RELOAD_SUCCESS["$url"]=0
        RELOAD_FAIL["$url"]=0
        LAST_STATUS["$url"]="–"
        LAST_RESPONSE_TIME["$url"]="–"
        PREV_STATUS["$url"]="–"
    done
    trap cleanup EXIT INT TERM
}

cleanup() {
    rm -f "$PID_FILE" "$LOCK_FILE"
    log_write "INFO" "Script dihentikan. Total reload: $TOTAL_UPTIME_RELOAD"
    exit 0
}

log_write() {
    [[ "$ENABLE_LOG" != "true" ]] && return
    local level="$1" message="$2"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [$level] $message" >> "$LOG_FILE"
    local lines; lines=$(wc -l < "$LOG_FILE")
    if [[ "$lines" -gt "$MAX_LOG_LINES" ]]; then
        tail -n "$MAX_LOG_LINES" "$LOG_FILE" > "${LOG_FILE}.tmp" && mv "${LOG_FILE}.tmp" "$LOG_FILE"
    fi
}

send_notification() {
    [[ "$ENABLE_NOTIFICATION" != "true" ]] && return
    command -v termux-notification &>/dev/null || return
    termux-notification --title "$1" --content "$2" --id "keepalive_$$" --priority high &>/dev/null &
}

check_internet() {
    curl -s --max-time 5 --head "https://connectivitycheck.gstatic.com/generate_204" \
        -o /dev/null -w "%{http_code}" 2>/dev/null | grep -q "204"
}

wait_for_internet() {
    local was_down=false
    while ! check_internet; do
        if [[ "$was_down" == "false" ]]; then
            INTERNET_STATUS="OFFLINE"
            log_write "WARN" "Internet terputus. Menunggu..."
            send_notification "⚠️ Internet Putus" "Reload dijeda, menunggu koneksi..."
            was_down=true
        fi
        sleep "$RETRY_WAIT"
    done
    if [[ "$was_down" == "true" ]]; then
        INTERNET_STATUS="ONLINE"
        log_write "INFO" "Internet kembali. Reload dilanjutkan."
        send_notification "✅ Internet Kembali" "Reload website dilanjutkan."
    fi
    INTERNET_STATUS="ONLINE"
}

# ── RELOAD WEBSITE (curl hit = simulasi kunjungan) ────────────
reload_website() {
    local url="$1"
    local method="${REQUEST_METHOD:-GET}"
    local start end elapsed http_code

    start=$(date +%s%3N)

    # Kirim request lengkap dengan header seperti browser biasa
    # agar server menganggap ada pengunjung nyata
    if [[ "$method" == "HEAD" ]]; then
        http_code=$(curl -s -o /dev/null -w "%{http_code}" \
            --max-time "$REQUEST_TIMEOUT" \
            -H "User-Agent: Mozilla/5.0 (Android; Mobile)" \
            -H "Accept: text/html,application/xhtml+xml" \
            -H "Connection: keep-alive" \
            --head "$url" 2>/dev/null)
    else
        http_code=$(curl -s -o /dev/null -w "%{http_code}" \
            --max-time "$REQUEST_TIMEOUT" \
            -H "User-Agent: Mozilla/5.0 (Android; Mobile)" \
            -H "Accept: text/html,application/xhtml+xml" \
            -H "Connection: keep-alive" \
            "$url" 2>/dev/null)
    fi

    end=$(date +%s%3N)
    elapsed=$(( end - start ))

    LAST_RESPONSE_TIME["$url"]="${elapsed}ms"
    LAST_STATUS["$url"]="$http_code"
    LAST_RELOAD_TIME=$(date '+%H:%M:%S')
    TOTAL_RELOAD["$url"]=$(( ${TOTAL_RELOAD["$url"]} + 1 ))
    TOTAL_UPTIME_RELOAD=$(( TOTAL_UPTIME_RELOAD + 1 ))

    local prev="${PREV_STATUS["$url"]}"
    if [[ "$http_code" =~ ^2 ]] || [[ "$http_code" =~ ^3 ]]; then
        RELOAD_SUCCESS["$url"]=$(( ${RELOAD_SUCCESS["$url"]} + 1 ))
        if [[ "$prev" == "offline" ]]; then
            log_write "OK" "[$url] Kembali online – HTTP $http_code – ${elapsed}ms"
            send_notification "✅ Website Online" "$url kembali dapat diakses"
        else
            log_write "OK" "[$url] Reload #${TOTAL_RELOAD["$url"]} – HTTP $http_code – ${elapsed}ms"
        fi
        PREV_STATUS["$url"]="online"
    else
        RELOAD_FAIL["$url"]=$(( ${RELOAD_FAIL["$url"]} + 1 ))
        if [[ "$prev" != "offline" ]]; then
            log_write "ERROR" "[$url] GAGAL – HTTP $http_code – ${elapsed}ms"
            send_notification "🔴 Website Offline!" "$url tidak dapat diakses (HTTP $http_code)"
            PREV_STATUS["$url"]="offline"
        else
            log_write "WARN" "[$url] Masih offline – HTTP $http_code"
        fi
    fi
}

get_uptime_str() {
    local elapsed=$(( $(date +%s) - START_TIME ))
    printf "%02d:%02d:%02d" $(( elapsed/3600 )) $(( (elapsed%3600)/60 )) $(( elapsed%60 ))
}

status_icon() {
    local code="$1"
    if [[ "$code" =~ ^2 ]]; then echo -e "${GREEN}${code} ✓ Online${RESET}"
    elif [[ "$code" =~ ^3 ]]; then echo -e "${YELLOW}${code} ↪ Redirect${RESET}"
    elif [[ "$code" =~ ^[45] ]]; then echo -e "${RED}${code} ✗ Offline${RESET}"
    elif [[ "$code" == "–" ]]; then echo -e "${DIM}Menunggu reload pertama...${RESET}"
    else echo -e "${DIM}–${RESET}"; fi
}

progress_bar() {
    local current="$1"
    local total="$2"
    local width=30
    local filled=$(( (total - current) * width / total ))
    local empty=$(( width - filled ))
    local bar=""
    for ((i=0; i<filled; i++)); do bar+="█"; done
    for ((i=0; i<empty; i++)); do bar+="░"; done
    echo -e "${CYAN}${bar}${RESET} ${current}s"
}

draw_dashboard() {
    [[ "$ENABLE_DASHBOARD" != "true" ]] && return
    clear
    local now countdown
    now=$(date +%s)
    countdown=$(( NEXT_RELOAD - now ))
    [[ "$countdown" -lt 0 ]] && countdown=0

    local interval
    interval=$(grep "^REFRESH_INTERVAL=" "$SCRIPT_DIR/config.sh" | cut -d'=' -f2)

    # Header
    echo -e "${BOLD}${CYAN}╔══════════════════════════════════════════════════════╗${RESET}"
    echo -e "${BOLD}${CYAN}║     🔄  KEEPALIVE PRO — Auto Reload 24/7             ║${RESET}"
    echo -e "${BOLD}${CYAN}╚══════════════════════════════════════════════════════╝${RESET}"
    echo ""

    # Info umum
    echo -e "  ${WHITE}Uptime        :${RESET} ${CYAN}$(get_uptime_str)${RESET}"
    if [[ "$INTERNET_STATUS" == "ONLINE" ]]; then
        echo -e "  ${WHITE}Internet      :${RESET} ${GREEN}● ONLINE${RESET}"
    else
        echo -e "  ${WHITE}Internet      :${RESET} ${RED}● OFFLINE — Menunggu koneksi...${RESET}"
    fi
    echo -e "  ${WHITE}Last Reload   :${RESET} ${LAST_RELOAD_TIME}"
    echo -e "  ${WHITE}Total Reload  :${RESET} ${MAGENTA}${TOTAL_UPTIME_RELOAD}x${RESET} sejak start"
    echo -e "  ${WHITE}Interval      :${RESET} ${YELLOW}${interval}s${RESET} ${DIM}($(( interval / 60 ))m $(( interval % 60 ))s)${RESET}"
    echo ""

    # Progress bar countdown
    echo -e "  ${WHITE}Next Reload   :${RESET} $(progress_bar "$countdown" "$interval")"
    echo ""

    # Website status
    echo -e "  ${BOLD}${BLUE}── Status Website ──────────────────────────────────${RESET}"
    echo ""

    local i=1
    for url in "${WEBSITES[@]}"; do
        local short="${url:0:50}"
        [[ ${#url} -gt 50 ]] && short="${url:0:47}..."
        local code="${LAST_STATUS["$url"]}"
        local rtime="${LAST_RESPONSE_TIME["$url"]}"
        local total="${TOTAL_RELOAD["$url"]}"
        local ok="${RELOAD_SUCCESS["$url"]}"
        local fail="${RELOAD_FAIL["$url"]}"

        # Hitung success rate
        local rate="–"
        if [[ "$total" -gt 0 ]]; then
            rate=$(( ok * 100 / total ))
            rate="${rate}%"
        fi

        printf "  ${BOLD}[%d]${RESET} ${CYAN}%s${RESET}\n" "$i" "$short"
        printf "      Status   : %s\n" "$(status_icon "$code")"
        printf "      Response : ${YELLOW}%-12s${RESET} Reload: ${MAGENTA}%sx${RESET}\n" "$rtime" "$total"
        printf "      Sukses   : ${GREEN}%-6s${RESET}         Gagal : ${RED}%sx${RESET}\n" "$rate" "$fail"
        echo ""
        (( i++ ))
    done

    echo -e "  ${BOLD}${BLUE}────────────────────────────────────────────────────${RESET}"
    echo -e "  ${DIM}Log  : $LOG_FILE${RESET}"
    echo -e "  ${DIM}Ctrl+C untuk berhenti  |  keepalive help untuk perintah${RESET}"
}

main_loop() {
    log_write "INFO" "=== Keepalive Pro dimulai. PID: $$. ${#WEBSITES[@]} website. Interval: ${REFRESH_INTERVAL}s ==="
    draw_dashboard

    while true; do
        wait_for_internet

        # Reload semua website
        for url in "${WEBSITES[@]}"; do
            reload_website "$url"
        done

        NEXT_RELOAD=$(( $(date +%s) + REFRESH_INTERVAL ))
        draw_dashboard

        # Countdown dengan update setiap 5 detik
        local remaining=$REFRESH_INTERVAL
        while (( remaining > 0 )); do
            sleep 1
            (( remaining-- ))
            if (( remaining % 5 == 0 )); then
                draw_dashboard
            fi
        done
    done
}

init
main_loop
