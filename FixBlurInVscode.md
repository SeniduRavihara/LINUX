# VS Code Wayland Fractional Scaling Fix

## Problem

When using VS Code on Wayland with fractional scaling enabled, Electron applications appear blurry. This happens because VS Code runs through XWayland by default instead of native Wayland.

## Solution

Force VS Code to run natively on Wayland by adding specific flags to the launch command.

---

## Step-by-Step Fix

### Step 1: Remove Snap Version (if installed)

```bash
sudo snap remove code
```

### Step 2: Install VS Code via DEB Package

Add Microsoft repository:

```bash
wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg
sudo install -D -o root -g root -m 644 packages.microsoft.gpg /etc/apt/keyrings/packages.microsoft.gpg
echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" | sudo tee /etc/apt/sources.list.d/vscode.list
```

Install VS Code:

```bash
sudo apt update
sudo apt install code
```

### Step 3: Test the Fix

First, test if the flags work by launching VS Code from terminal:

```bash
code --enable-features=UseOzonePlatform --ozone-platform-hint=auto
```

You should notice VS Code is now sharp and crisp with fractional scaling.

### Step 4: Make It Permanent

Copy the desktop file to your local applications folder:

```bash
cp /usr/share/applications/code.desktop ~/.local/share/applications/
```

Edit the desktop file:

```bash
nano ~/.local/share/applications/code.desktop
```

### Step 5: Update the Desktop File

Replace the contents with this:

```ini
[Desktop Entry]
Name=Visual Studio Code
Comment=Code Editing. Redefined.
GenericName=Text Editor
Exec=/usr/share/code/code --enable-features=UseOzonePlatform --ozone-platform-hint=auto %F
Icon=vscode
Type=Application
StartupNotify=false
StartupWMClass=Code
Categories=TextEditor;Development;IDE;
MimeType=application/x-code-workspace;
Actions=new-empty-window;
Keywords=vscode;

[Desktop Action new-empty-window]
Name=New Empty Window
Name[cs]=Nové prázdné okno
Name[de]=Neues leeres Fenster
Name[es]=Nueva ventana vacía
Name[fr]=Nouvelle fenêtre vide
Name[it]=Nuova finestra vuota
Name[ja]=新しい空のウィンドウ
Name[ko]=새 빈 창
Name[ru]=Новое пустое окno
Name[zh_CN]=新建空窗口
Name[zh_TW]=開新空視窗
Exec=/usr/share/code/code --enable-features=UseOzonePlatform --ozone-platform-hint=auto --new-window %F
Icon=vscode
```

**Key changes:**

- Main Exec line: Added `--enable-features=UseOzonePlatform --ozone-platform-hint=auto`
- New window Exec line: Added the same flags before `--new-window`

### Step 6: Update Desktop Database

Save the file and update the desktop database:

```bash
update-desktop-database ~/.local/share/applications/
```

### Step 7: Restart VS Code

Close all VS Code instances completely and launch it from your application menu. It should now be sharp with fractional scaling enabled!

---

## Verification

To verify VS Code is running with the correct flags, open a terminal and run:

```bash
ps aux | grep "/usr/share/code/code" | grep -v grep
```

You should see the `--enable-features` and `--ozone-platform-hint` flags in the output.

---

## Notes

- The warnings about `'enable-features'` and `'ozone-platform-hint'` not being in the list of known options are **normal and harmless**. These flags are being passed to the underlying Chromium engine correctly.
- Your local desktop file at `~/.local/share/applications/code.desktop` takes priority over the system-wide one, so your settings will persist even after VS Code updates.
- If you experience window decoration issues, you can change the title bar style in VS Code settings: Search for "title bar" and change `Window: Title Bar Style` from "native" to "custom".

---

## Why This Works

- **Snap version issue**: The Snap version of VS Code doesn't support native Wayland properly and is forced to run through XWayland
- **XWayland + Fractional Scaling = Blur**: When fractional scaling is enabled on Wayland, XWayland applications get upscaled, causing blurriness
- **Native Wayland**: By forcing VS Code to run natively on Wayland with these flags, it bypasses XWayland and renders sharply at the correct scaling factor

---

## Alternative: Android Emulator on Wayland

If you also use Android Emulator and had issues with it on X11, you can run it on Wayland with:

```bash
QT_QPA_PLATFORM=xcb emulator -avd YourAVDName
```

Or use software rendering:

```bash
emulator -avd YourAVD -gpu guest
```

This allows you to stay on Wayland for both VS Code and Android development!
