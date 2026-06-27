#!/bin/bash
# ============================================================
#  RAM Watchdog Installer
#  Sets up ram_watchdog.sh to auto-start on every login.
# ============================================================

SCRIPT_NAME="ram_watchdog.sh"
INSTALL_DIR="$HOME/.local/bin"
INSTALL_PATH="$INSTALL_DIR/$SCRIPT_NAME"
AUTOSTART_DIR="$HOME/.config/autostart"
AUTOSTART_FILE="$AUTOSTART_DIR/ram_watchdog.desktop"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  RAM Watchdog — Installer"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# 1. Check that ram_watchdog.sh is present alongside this installer
if [[ ! -f "$SCRIPT_NAME" ]]; then
    echo "❌ ERROR: '$SCRIPT_NAME' not found in current directory."
    echo "   Place both files in the same folder and re-run."
    exit 1
fi

# 2. Install the script
mkdir -p "$INSTALL_DIR"
cp "$SCRIPT_NAME" "$INSTALL_PATH"
chmod +x "$INSTALL_PATH"
echo "✅ Installed to: $INSTALL_PATH"

# 3. Create systemd user service directory
mkdir -p "$HOME/.config/systemd/user"

# 4. Create the service file
SERVICE_FILE="$HOME/.config/systemd/user/ram-watchdog.service"
cat > "$SERVICE_FILE" <<EOF
[Unit]
Description=RAM Watchdog Service
After=network.target

[Service]
ExecStart=$INSTALL_PATH
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=default.target
EOF
echo "✅ Systemd service created: $SERVICE_FILE"

# 5. Load, Enable and Start the service
systemctl --user daemon-reload
systemctl --user enable ram-watchdog.service
systemctl --user restart ram-watchdog.service

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  RAM Watchdog is now RUNNING (systemd) 🚀"
echo "  Check status: systemctl --user status ram-watchdog.service"
echo "  View logs:    journalctl --user -u ram-watchdog.service -f"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
