# Custom File Path Copier for Fedora Linux

This guide provides instructions on how to add functionality to Fedora Linux that allows you to copy the full absolute path of a selected file (e.g., `/home/user/Documents/test.txt`) directly to your clipboard using either a **Right-Click Context Menu** or a **Keyboard Shortcut**.

Since modern Fedora defaults to the **GNOME** desktop environment running on the **Wayland** display server, these solutions leverage native desktop features and `wl-clipboard`.

---

## Prerequisites

Before setting up either method, you must install the utility that enables scripts to interact with the system clipboard.

Open your terminal and execute:

```bash
sudo dnf install wl-clipboard
```

*Note: If you have manually switched your desktop session to X11 instead of Wayland, install `xclip` (`sudo dnf install xclip`) instead.*

---

## Option A: Add to the Right-Click Context Menu (Recommended)

GNOME's file manager (Nautilus) natively supports custom user scripts. Adding a script to the dedicated configuration folder will automatically create an option in your right-click context menu under a "Scripts" submenu.

### Setup Instructions:

1. Open your terminal and create a new script file in your user-specific Nautilus directory:
   ```bash
   nano ~/.local/share/nautilus/scripts/"Copy Full Path"
   ```

2. Copy and paste the following bash script into the editor:
   ```bash
   #!/bin/bash
   
   # Nautilus automatically passes selected file paths via the environment variable
   # We use 'echo -n' to prevent trailing newlines and pass it to the Wayland clipboard
   echo -n "$NAUTILUS_SCRIPT_SELECTED_FILE_PATHS" | wl-copy
   ```
   *(If you are running an X11 session, replace `wl-copy` with `xclip -selection clipboard`)*

3. Save the file and exit the text editor (in `nano`, press `Ctrl + O`, then `Enter`, followed by `Ctrl + X`).

4. Grant executable permissions to the script so the file manager can run it:
   ```bash
   chmod +x ~/.local/share/nautilus/scripts/"Copy Full Path"
   ```

### How to Use It:
* Open your file manager and **right-click** on any file or folder.
* Navigate to the **Scripts** cascading menu.
* Click on **Copy Full Path**.
* The absolute file path is now stored in your clipboard, ready to be pasted (`Ctrl + V`).

---

## Option B: Use the Built-In Keyboard Shortcut

If your main goal is to quickly grab a file's path via a hotkey without clicking through context menus, Fedora's default file manager has this capability **built-in out of the box**.

### How to Use It:
1. Open your file manager and click once on the desired file to highlight it.
2. Press **`Ctrl + C`** (the traditional copy command).
3. Move your cursor to any text field, terminal window, or text editor, and press **`Ctrl + V`**.

**Why this works:** In the GNOME desktop environment, copying a file copies both the file object (for moving/duplicating in the file manager) and its literal string path. When you paste into a text-only destination, it automatically defaults to pasting the full path (e.g., `/path/to/file.txt`).
