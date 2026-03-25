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

# 3. Add ~/.local/bin to PATH if not already there
if ! echo "$PATH" | grep -q "$INSTALL_DIR"; then
    SHELL_RC="$HOME/.bashrc"
    [[ -f "$HOME/.zshrc" ]] && SHELL_RC="$HOME/.zshrc"
    echo "export PATH=\"\$PATH:$INSTALL_DIR\"" >> "$SHELL_RC"
    echo "✅ Added $INSTALL_DIR to PATH in $SHELL_RC"
fi

# 4. Create autostart .desktop entry (works on GNOME, KDE, XFCE)
mkdir -p "$AUTOSTART_DIR"
cat > "$AUTOSTART_FILE" <<EOF
[Desktop Entry]
Type=Application
Name=RAM Watchdog
Comment=Monitors RAM and kills Chrome if usage is too high
Exec=bash -c 'sleep 10 && $INSTALL_PATH --daemon'
Terminal=false
Hidden=false
X-GNOME-Autostart-enabled=true
EOF
echo "✅ Autostart entry created: $AUTOSTART_FILE"

# 5. Start it right now
"$INSTALL_PATH" --daemon
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  RAM Watchdog is now RUNNING 🚀"
echo "  Log file: ~/.ram_watchdog.log"
echo ""
echo "  Useful commands:"
echo "  • View live log:  tail -f ~/.ram_watchdog.log"
echo "  • Stop watchdog:  pkill -f ram_watchdog.sh"
echo "  • Check if alive: pgrep -f ram_watchdog.sh"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
