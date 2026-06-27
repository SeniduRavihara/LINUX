# 🚀 RAM Watchdog (4-Stage Intelligent Kill)

A high-performance Linux bash script to monitor RAM usage and prevent system freezes with a progressive, intelligent approach to managing resource-heavy processes like Chrome, Brave, and AI-driven build commands.

## 🛠 Features

*   **Build Process Protection (Stage 0)**: Detects and terminates `npm run build`, `next build`, or `vite build` processes immediately if RAM hits critical levels.
*   **AI Agent Communication**: Automatically sends a clear explanation message to the terminal of any killed build process, explaining *why* it was terminated so AI agents (or you) aren't confused by the sudden exit.
*   **Brave & Chrome Management**: Progressive approach to browser memory management.
*   **4-Stage Progressive Action (at 95% RAM)**:
    1.  **Stage 0: Build Kill**: Terminates active build processes and notifies the terminal.
    2.  **Stage 1: Brave Kill**: Force-kills **Brave fully**.
    3.  **Interactive Stage**: If RAM is still high, an interactive **zenity prompt** (10s timeout) asks if you want to close **Chrome tabs** (renderer processes) while keeping the main window.
    4.  **Stage 2: Emergency Kill**: Force-kills **Chrome fully** as a final safety measure.
*   **Intelligent Re-checks**: Each stage only triggers if RAM remains critically high after the previous action.
*   **60s Grace Period**: After any kill action, the watchdog enters a 1-minute cooldown to let the system stabilize.
*   **High Sensitivity**: Checks RAM every **3 seconds**.
*   **Reliable Management**: Runs as a **systemd user service** for robust background operation and automatic restarts.

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
