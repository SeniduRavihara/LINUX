# 🚀 RAM Watchdog (3-Stage Intelligent Kill)

A high-performance Linux bash script to monitor RAM usage and prevent system freezes with a progressive, intelligent approach to managing Chrome and Brave.

## 🛠 Features

*   **Brave Priority**: Brave is completely closed before Chrome is touched.
*   **3-Stage Progressive Action (at 95% RAM)**:
    1.  **Stage 1: Brave Kill**: Force-kills **Brave fully**.
    2.  **Interactive Stage**: If RAM is still high, an interactive **zenity prompt** (10s timeout) asks if you want to close **Chrome tabs** (renderer processes) while keeping the main window.
    3.  **Stage 2: Emergency Kill**: Force-kills **Chrome fully** as a final safety measure.
*   **Intelligent Re-checks**: Each stage only triggers if RAM remains critically high after the previous action.
*   **60s Grace Period**: After any kill action, the watchdog enters a 1-minute cooldown to let the system stabilize.
*   **High Sensitivity**: Checks RAM every **3 seconds**.
*   **Reliable Management**: Now runs as a **systemd user service** for robust background operation and automatic restarts.

## 📥 Installation

1. Copy both `ram_watchdog.sh` and `install_watchdog.sh` to a directory.
2. Run the installer:
   ```bash
   chmod +x *.sh
   ./install_watchdog.sh
   ```

The script will be installed to `~/.local/bin/ram_watchdog.sh` and set up as a systemd service.

## ⚙️ Management (systemd)

*   **View status**: `systemctl --user status ram-watchdog.service`
*   **Live logs**: `journalctl --user -u ram-watchdog.service -f`
*   **Stop**: `systemctl --user stop ram-watchdog.service`
*   **Start**: `systemctl --user start ram-watchdog.service`
*   **Restart**: `systemctl --user restart ram-watchdog.service`

---
*Created and maintained by Antigravity*
