# Sinhala Speech-to-Text using AGY Dictation

An automated pipeline that converts audio files (WhatsApp voice notes, Opus, Ogg, MP3, WAV, etc.) into accurate Sinhala text by utilizing Antigravity CLI's native Google Speech streaming engine (`/voice dictate`).

Location: `/home/senu/PROJECTS/LINUX/scripts/Speech_To_Text_AGY`

---

## Antigravity Skill Integration

A global Antigravity skill has been installed at:
`~/.gemini/config/skills/sinhala-speech-to-text/SKILL.md`

### How to Use inside ANY Antigravity Chat
When working in **any project** in Antigravity (LMS, AWS, web apps, etc.), you can simply tell Antigravity:
> *"Hey, transcribe this voice note: ~/Downloads/WhatsApp Ptt....ogg"*  
> or  
> *"Use the speech-to-text skill to transcribe my latest audio file"*

Antigravity will:
1. Locate the file (or ask you / open a file chooser if not specified).
2. Run the transcription engine silently in the background (`--no-gui`).
3. Automatically copy the Sinhala text to your system clipboard (`wl-copy`).
4. Paste the full transcript directly into your active chat conversation so you can use it immediately for prompts, documentation, user stories, or code!

---

## Standalone Usage

### 1. Interactive Mode (File Chooser + GUI Viewer)
Run the script without arguments:
```bash
bash "/home/senu/PROJECTS/LINUX/scripts/Speech_To_Text_AGY/voice-to-agy.sh"
```
- A file chooser dialog appears to select your audio file.
- The transcription progress is displayed in the terminal.
- When done, the text is automatically copied to your clipboard, and a modern window opens with a **Copy Text** button and full transcript view.

### 2. Command-Line Mode
Pass an audio file directly:
```bash
bash "/home/senu/PROJECTS/LINUX/scripts/Speech_To_Text_AGY/voice-to-agy.sh" "/path/to/recording.ogg"
```

### 3. Headless / Programmatic Mode
To get text output without opening a GUI window:
```bash
python3 "/home/senu/PROJECTS/LINUX/scripts/Speech_To_Text_AGY/voice-to-agy.py" --no-gui "/path/to/recording.ogg"
```

### 4. View Any Saved Transcript
Re-open any previously saved transcript in the viewer with the Copy button:
```bash
bash "/home/senu/PROJECTS/LINUX/scripts/Speech_To_Text_AGY/voice-to-agy.sh" "/home/senu/PROJECTS/LINUX/scripts/Speech_To_Text_AGY/transcripts/example.txt"
```

---

## Output Location
All transcripts are automatically saved to [`transcripts/`](./transcripts).
