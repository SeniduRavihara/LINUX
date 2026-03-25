# 🚀 RAM Watchdog (2-Stage Full Kill)

A high-performance Linux bash script to monitor RAM usage and prevent system freezes by managing memory-hungry browsers with a strict, 2-stage full closure approach.

## 🛠 Features

*   **Brave Priority**: Brave is completely closed before Chrome is even touched.
*   **2-Stage 95% Kill**:
    1.  **Stage 1**: Force-kill **Brave fully**. (No tab-killing).
    2.  **Stage 2**: Force-kill **Chrome fully** (EMERGENCY).
*   **No Tab Reload Cycles**: The script skips tab-killing entirely to avoid the frustration of reloading crashed tabs.
*   **Progressive Re-checks**: Stage 2 only triggers if RAM remains >= 95% on the next check (after Stage 1). If Stage 1 frees enough RAM, **Chrome stays safe.**
*   **60s Grace Period**: After any full browser closure, the watchdog enters a 1-minute cooldown.
*   **High Sensitivity**: Checks RAM every **3 seconds**.

## 📥 Installation

1. Copy both `ram_watchdog.sh` and `install_watchdog.sh` to a directory.
2. Run the installer:
   ```bash
   chmod +x *.sh
   ./install_watchdog.sh
   ```

The script will be installed to `~/.local/bin/ram_watchdog.sh`.

## ⚙️ Management

*   **View live logs**: `tail -f ~/.ram_watchdog.log`
*   **Check process**: `pgrep -f ram_watchdog.sh`
*   **Stop/Kill**: `pkill -f ram_watchdog.sh`
*   **Restart manually**: `~/.local/bin/ram_watchdog.sh --daemon`

---
*Created and maintained by Antigravity*
