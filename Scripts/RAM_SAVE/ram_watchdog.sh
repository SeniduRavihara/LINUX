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
    # Force-kill every Chrome process (target both chrome and google-chrome)
    local killed=0
    while IFS= read -r pid; do
        if [[ "$pid" != "$$" ]]; then
            kill -9 "$pid" 2>/dev/null && (( killed++ ))
        fi
    done < <(pgrep -f "chrome|google-chrome" 2>/dev/null)
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
        if [[ "$pid" != "$$" ]]; then
            kill -9 "$pid" 2>/dev/null && (( killed++ ))
        fi
    done < <(pgrep -f "brave" 2>/dev/null)
    echo "$killed"
}

kill_build_processes() {
    # Kill npm run build and related node processes (common in dev environments)
    local killed=0
    while IFS= read -r pid; do
        if [[ "$pid" != "$$" ]]; then
            # Try to send a message to the process's stdout before killing
            # This helps AI agents or users see why the process died
            if [[ -d "/proc/$pid/fd" ]]; then
                {
                    echo -e "\n\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
                    echo -e "⚠️  [RAM WATCHDOG] KILLING THIS PROCESS"
                    echo -e "REASON: RAM usage exceeded 95% (${RAM_PCT}%)."
                    echo -e "ACTION: System protection triggered to prevent freeze."
                    echo -e "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n"
                } > "/proc/$pid/fd/1" 2>/dev/null
            fi

            kill -9 "$pid" 2>/dev/null && (( killed++ ))
        fi
    done < <(pgrep -f "npm run build|next build|vite build" 2>/dev/null)
    echo "$killed"
}

kill_next_server() {
    # Kill Next.js dev server and related processes
    local killed=0
    while IFS= read -r pid; do
        if [[ "$pid" != "$$" ]]; then
            if [[ -d "/proc/$pid/fd" ]]; then
                {
                    echo -e "\n\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
                    echo -e "⚠️  [RAM WATCHDOG] KILLING NEXT SERVER"
                    echo -e "REASON: RAM usage exceeded 95% (${RAM_PCT}%)."
                    echo -e "ACTION: Next server terminated to prevent freeze."
                    echo -e "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n"
                } > "/proc/$pid/fd/1" 2>/dev/null
            fi
            kill -9 "$pid" 2>/dev/null && (( killed++ ))
        fi
    done < <(pgrep -f "next-server|next dev|npm run dev" 2>/dev/null)
    echo "$killed"
}

# ── State tracking ──────────────────────────────────────────
kill_stage=0            # 0=normal, 1=BraveAll, 2=ChromeAll

# ── Main loop ───────────────────────────────────────────────
log "INFO" "RAM Watchdog started. Threshold: ${KILL_THRESHOLD}% (3-Stage Kill: Brave → Next Server → Chrome)"
log "INFO" "Check interval: ${CHECK_INTERVAL}s | Log: ${LOG_FILE}"

trap 'log "INFO" "RAM Watchdog stopped."; exit 0' SIGINT SIGTERM

while true; do
    RAM_PCT=$(get_ram_percent)
    RAM_DETAILS=$(get_ram_details)

    # ── THRESHOLD AT 95% ────────────────────────────────────
    if (( RAM_PCT >= KILL_THRESHOLD )); then
        action_taken=false

        # Stage 1: Brave (Kill fully first)
        if pgrep -f "brave" | grep -v "$$" >/dev/null; then
            log "CRITICAL" "RAM hit ${RAM_PCT}% — Closing Brave fully."
            KILLED=$(kill_brave_all)
            if [[ "$KILLED" -gt 0 ]]; then
                notify "critical" "🚨 RAM 95% — Brave Closed" "Brave was force-killed to save memory!\nRAM: ${RAM_DETAILS}" "$ICON_CRITICAL"
                log "CRITICAL" "Killed: ${KILLED} Brave processes."
                action_taken=true
            fi
        fi

        # Stage 2: Next Server (If RAM still high)
        if (( RAM_PCT >= KILL_THRESHOLD )) || [[ "$action_taken" == "true" ]]; then
            # Re-check RAM if action was taken
            if [[ "$action_taken" == "true" ]]; then sleep 1; RAM_PCT=$(get_ram_percent); fi
            
            if (( RAM_PCT >= KILL_THRESHOLD )) && pgrep -f "next-server|next dev|npm run dev" | grep -v "$$" >/dev/null; then
                log "CRITICAL" "RAM still at ${RAM_PCT}% — Terminating Next server."
                KILLED=$(kill_next_server)
                if [[ "$KILLED" -gt 0 ]]; then
                    notify "critical" "🚨 RAM 95% — Next Server Terminated" "Next.js server was force-killed to save memory!\nRAM: ${RAM_DETAILS}" "$ICON_CRITICAL"
                    log "CRITICAL" "Killed: ${KILLED} Next server processes."
                    action_taken=true
                fi
            fi
        fi

        # Stage 0: Build processes (Also check if any heavy builds are running)
        if (( RAM_PCT >= KILL_THRESHOLD )); then
            if pgrep -f "npm run build|next build|vite build" | grep -v "$$" >/dev/null; then
                log "CRITICAL" "RAM hit ${RAM_PCT}% — Terminating build process."
                KILLED=$(kill_build_processes)
                if [[ "$KILLED" -gt 0 ]]; then
                    notify "critical" "🚨 RAM 95% — Build Terminated" "Build process was force-killed!\nRAM: ${RAM_DETAILS}" "$ICON_CRITICAL"
                    log "CRITICAL" "Killed: ${KILLED} build processes."
                    action_taken=true
                fi
            fi
        fi

        # Stage 3: Chrome (Interactive then Full)
        if (( RAM_PCT >= KILL_THRESHOLD )) || [[ "$action_taken" == "true" ]]; then
            # Re-check RAM
            sleep 2
            RAM_PCT=$(get_ram_percent)
            RAM_DETAILS=$(get_ram_details)

            if (( RAM_PCT >= KILL_THRESHOLD )) && pgrep -f "chrome|google-chrome" | grep -v "$$" >/dev/null; then
                export DISPLAY=:0 
                # Ask to kill tabs or full
                if zenity --question --text "Brave/Next closed, but RAM is still high (${RAM_PCT}%).\nShould I close Chrome TABS (keep window) or FULL kill Chrome?" --timeout=15 --title="RAM Watchdog Alert" --ok-label="Close TABS" --cancel-label="FULL Kill"; then
                    # User clicked "Close TABS"
                    KILLED=$(kill_chrome_tabs)
                    if [[ "$KILLED" -gt 0 ]]; then
                        notify "normal" "🧹 Chrome Tabs Closed" "Force-killed ${KILLED} renderer processes." "$ICON_WARN"
                        log "INFO" "User opted to kill ${KILLED} Chrome tabs."
                        sleep 2
                        RAM_PCT=$(get_ram_percent)
                    fi
                else
                    # User clicked "FULL Kill" or timeout
                    # If timeout, we check if we should be safe and kill all
                    log "INFO" "User opted for FULL Chrome kill or prompt timed out."
                    KILLED=$(kill_chrome_all)
                    if [[ "$KILLED" -gt 0 ]]; then
                        notify "critical" "🚨 RAM 95% — Chrome Closed" "Chrome was fully closed.\nRAM: ${RAM_DETAILS}" "$ICON_CRITICAL"
                        log "CRITICAL" "Killed: ${KILLED} Chrome processes."
                        action_taken=true
                    fi
                fi
            fi
        fi

        # Final check for Chrome if it's still alive and RAM is still critical
        if (( RAM_PCT >= KILL_THRESHOLD )) && pgrep -f "chrome|google-chrome" | grep -v "$$" >/dev/null; then
            log "CRITICAL" "RAM still at ${RAM_PCT}% — EMERGENCY: Closing Chrome fully."
            KILLED=$(kill_chrome_all)
            if [[ "$KILLED" -gt 0 ]]; then
                notify "critical" "🚨 RAM 95% — Chrome Closed" "Chrome force-killed as final measure." "$ICON_CRITICAL"
                log "CRITICAL" "Killed: ${KILLED} Chrome processes."
                action_taken=true
            fi
        fi

        # Cooldown period if any action was taken
        if [[ "$action_taken" == "true" ]]; then
            log "INFO" "Entering 60s cooldown to allow system stabilization."
            sleep 60
        fi
        
        continue

    # ── RAM Normal ──────────────────────────────────────────
    fi

    sleep "$CHECK_INTERVAL"
done
