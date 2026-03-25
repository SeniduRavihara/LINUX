#!/bin/bash
# ============================================================
#  RAM Watchdog — ram_watchdog.sh
#  Monitors RAM usage and kills Chrome before your laptop freezes.
#
#  Thresholds:
#    85% → Desktop warning notification
#    90% → Urgent notification + kill Chrome tabs (keep window)
#    95% → Force-kill ALL Chrome processes
#
#  Usage:
#    chmod +x ram_watchdog.sh
#    ./ram_watchdog.sh          # Run in foreground
#    ./ram_watchdog.sh &        # Run in background
#    ./ram_watchdog.sh --daemon # Run as background daemon (logs to file)
# ============================================================

# ── Config ──────────────────────────────────────────────────
WARN_THRESHOLD=0        # Disabled
KILL_THRESHOLD=95       # % RAM → main action threshold
CHECK_INTERVAL=3        # seconds between each RAM check
LOG_FILE="$HOME/.ram_watchdog.log"
MAX_LOG_LINES=500       # rotate log after this many lines

# Notification icon (fallback gracefully if not found)
ICON_WARN="dialog-warning"
ICON_CRITICAL="dialog-error"
# ────────────────────────────────────────────────────────────

# ── Daemon mode ─────────────────────────────────────────────
if [[ "$1" == "--daemon" ]]; then
    nohup "$0" >> "$LOG_FILE" 2>&1 &
    echo "✅ RAM Watchdog started as daemon (PID $!)"
    echo "   Log file: $LOG_FILE"
    echo "   To stop: kill $!"
    exit 0
fi

# ── Helpers ─────────────────────────────────────────────────
log() {
    local level="$1"; shift
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [$level] $*"
    # Rotate log if too large
    if [[ -f "$LOG_FILE" ]]; then
        local lines
        lines=$(wc -l < "$LOG_FILE")
        if (( lines > MAX_LOG_LINES )); then
            tail -n $((MAX_LOG_LINES / 2)) "$LOG_FILE" > "${LOG_FILE}.tmp" \
                && mv "${LOG_FILE}.tmp" "$LOG_FILE"
        fi
    fi
}

notify() {
    local urgency="$1"   # normal | critical
    local title="$2"
    local body="$3"
    local icon="$4"
    # Try notify-send (works on GNOME, KDE, XFCE, etc.)
    if command -v notify-send &>/dev/null; then
        notify-send -u "$urgency" -i "$icon" "$title" "$body" 2>/dev/null
    fi
}

get_ram_percent() {
    # Uses /proc/meminfo for accuracy — works on all Linux distros
    local total available
    total=$(grep MemTotal /proc/meminfo | awk '{print $2}')
    available=$(grep MemAvailable /proc/meminfo | awk '{print $2}')
    local used=$(( total - available ))
    echo $(( used * 100 / total ))
}

get_ram_details() {
    local total available used
    total=$(grep MemTotal /proc/meminfo | awk '{print $2}')
    available=$(grep MemAvailable /proc/meminfo | awk '{print $2}')
    used=$(( (total - available) / 1024 ))
    total=$(( total / 1024 ))
    echo "${used}MB / ${total}MB"
}

kill_chrome_tabs() {
    # Kill only renderer processes (tabs) — keeps the Chrome window alive
    local killed=0
    while IFS= read -r pid; do
        kill -9 "$pid" 2>/dev/null && (( killed++ ))
    done < <(pgrep -f "chrome.*--type=renderer" 2>/dev/null)
    echo "$killed"
}

kill_chrome_all() {
    # Force-kill every Chrome process
    local killed=0
    while IFS= read -r pid; do
        kill -9 "$pid" 2>/dev/null && (( killed++ ))
    done < <(pgrep -f "chrome" 2>/dev/null)
    echo "$killed"
}

kill_brave_tabs() {
    # Kill only renderer processes (tabs) — keeps the Brave window alive
    local killed=0
    while IFS= read -r pid; do
        kill -9 "$pid" 2>/dev/null && (( killed++ ))
    done < <(pgrep -f "brave.*--type=renderer" 2>/dev/null)
    echo "$killed"
}

kill_brave_all() {
    # Force-kill every Brave process
    local killed=0
    while IFS= read -r pid; do
        kill -9 "$pid" 2>/dev/null && (( killed++ ))
    done < <(pgrep -f "brave" 2>/dev/null)
    echo "$killed"
}

# ── State tracking ──────────────────────────────────────────
kill_stage=0            # 0=normal, 1=BraveAll, 2=ChromeAll
cooldown_seconds=0      # grace period after any kill action

# ── Main loop ───────────────────────────────────────────────
log "INFO" "RAM Watchdog started. Threshold: ${KILL_THRESHOLD}% (2-Stage Full Kill: Brave → Chrome)"
log "INFO" "Check interval: ${CHECK_INTERVAL}s | Log: ${LOG_FILE}"

trap 'log "INFO" "RAM Watchdog stopped."; exit 0' SIGINT SIGTERM

while true; do
    RAM_PCT=$(get_ram_percent)
    RAM_DETAILS=$(get_ram_details)

    # ── Cooldown check ──────────────────────────────────────
    if (( cooldown_seconds > 0 )); then
        (( cooldown_seconds -= CHECK_INTERVAL ))
        sleep "$CHECK_INTERVAL"
        continue
    fi

    # ── THRESHOLD AT 95% ────────────────────────────────────
    if (( RAM_PCT >= KILL_THRESHOLD )); then
        (( kill_stage++ ))

        case "$kill_stage" in
            1)
                log "CRITICAL" "RAM hit ${RAM_PCT}% (Stage 1) — Closing Brave fully."
                KILLED=$(kill_brave_all)
                notify "critical" "🚨 RAM 95% — Brave Closed" "Stage 1: Brave was force-killed to save memory!\nCooldown: 60s.\nRAM: ${RAM_DETAILS}" "$ICON_CRITICAL"
                log "CRITICAL" "Killed: ${KILLED} Brave processes."
                kill_stage=0
                cooldown_seconds=60 
                ;;
            2)
                log "CRITICAL" "RAM still at ${RAM_PCT}% (Stage 2) — EMERGENCY: Closing Chrome fully."
                KILLED=$(kill_chrome_all)
                notify "critical" "🚨 RAM 95% — Chrome Closed" "Stage 2: Chrome was force-killed!\nCooldown: 60s.\nRAM: ${RAM_DETAILS}" "$ICON_CRITICAL"
                log "CRITICAL" "Killed: ${KILLED} Chrome processes."
                kill_stage=0
                cooldown_seconds=60 # Long cooldown after final stage
                ;;
        esac

        # Short cooldown/wait between stages
        sleep 2
        continue

    # ── RAM Normal ──────────────────────────────────────────
    else
        if [[ "$kill_stage" -gt 0 ]]; then
            log "INFO" "RAM recovered to ${RAM_PCT}% after Stage ${kill_stage}."
        fi
        kill_stage=0
    fi

    sleep "$CHECK_INTERVAL"
done
