# Sinhala Speech-to-Text using AGY Dictation

An automated pipeline that converts audio files (WhatsApp voice notes, Opus, Ogg, MP3, WAV, etc.) into accurate Sinhala text directly to your clipboard and screen by utilizing Antigravity CLI's native Google Speech streaming engine (`/voice dictate`).

Location: `/home/senu/PROJECTS/LINUX/scripts/Speech_To_Text_AGY`

---

## Zero-Clutter Architecture
- **No File Saving**: By default, no files are written to disk. All processing occurs in temporary memory space and cleans up automatically.
- **Direct Clipboard Copy**: Transcribed text is automatically copied straight to your system clipboard (`wl-copy`), ready to paste (`Ctrl+V`) instantly.
- **Direct Chat Output**: When called from Antigravity, the text is pasted straight into the conversation.

---

## Antigravity Skill Integration

A global Antigravity skill is installed at:
`~/.gemini/config/skills/sinhala-speech-to-text/SKILL.md`

### How to Use inside ANY Antigravity Chat
When working in **any project** in Antigravity, simply tell Antigravity:
> *"Hey, transcribe this voice note: ~/Downloads/WhatsApp Ptt....ogg"*  
> or  
> *"Use the speech-to-text skill to transcribe my latest audio file"*

Antigravity will:
1. Run the transcription engine silently in the background (`--no-gui`).
2. Copy the Sinhala text to your system clipboard (`wl-copy`).
3. Output the text directly into the chat conversation. No files are saved to disk.

---

## Standalone Usage

### 1. Interactive Mode (File Chooser + GUI Viewer)
Run the script without arguments:
```bash
bash "/home/senu/PROJECTS/LINUX/scripts/Speech_To_Text_AGY/voice-to-agy.sh"
```
- Select your audio file in the file chooser.
- The text is copied to your clipboard, and a clean window opens with a **Copy Text** button to review or edit.

### 2. Command-Line / Script Mode
```bash
python3 "/home/senu/PROJECTS/LINUX/scripts/Speech_To_Text_AGY/voice-to-agy.py" --no-gui "/path/to/recording.ogg"
```
*(Optionally pass `--save <path>` if you ever explicitly want to save a file.)*
