---
name: sinhala-speech-to-text
description: >-
  Transcribes voice notes and audio recordings (WhatsApp voice messages, ogg, opus, mp3, wav, m4a, flac)
  containing Sinhala or multilingual speech into accurate text using the local AGY dictation engine.
  Use when the user asks to transcribe an audio file, convert voice/speech to text, or ingest voice notes into the project.
---

# Sinhala Speech-to-Text Skill

Transcribes audio recordings into Sinhala text using the high-accuracy local AGY speech loop at `/home/senu/PROJECTS/LINUX/scripts/Speech_To_Text_AGY/voice-to-agy.py`.

## When to Use
- User says "use this skill", "transcribe this audio", "convert voice note to text", or asks to extract text from a recording.
- User shares or references an audio file (`.ogg`, `.opus`, `.wav`, `.mp3`, `.m4a`, `.aac`).
- User has WhatsApp voice notes in `~/Downloads` that need to be converted to requirements, documentation, or code.

## Workflow

### 1. Identify the Audio File
- If the user provided a file path, verify it exists.
- If the user did not provide a path, ask them for the path or check `~/Downloads` for recent voice notes:
  ```bash
  ls -lt ~/Downloads/*.{ogg,opus,wav,mp3,m4a} 2>/dev/null | head -n 5
  ```
- Alternatively, launch the graphical file picker so the user can choose visually:
  ```bash
  zenity --file-selection --title="Choose an audio file" --filename="$HOME/Downloads/" --file-filter="Audio | *.ogg *.opus *.wav *.mp3 *.m4a *.flac"
  ```

### 2. Execute Transcription
Run the transcription engine with `--no-gui` to capture the output directly into your tool response:
```bash
python3 /home/senu/PROJECTS/LINUX/scripts/Speech_To_Text_AGY/voice-to-agy.py --no-gui "/absolute/path/to/audio/file"
```

*(Note: If the user explicitly asks for the graphical viewer window with the Copy button, omit `--no-gui`.)*

### 3. Parse and Present the Result
- The command outputs the recognized text between `=== TRANSCRIPT START ===` and `=== TRANSCRIPT END ===`.
- The complete transcript is saved in `/home/senu/PROJECTS/LINUX/scripts/Speech_To_Text_AGY/transcripts/`.
- The text is also automatically copied to the user's system clipboard (`wl-copy`).
- Display the transcribed text directly to the user in your response and proceed with any tasks requested on that text (summarizing, implementing features, documentation, etc.).
