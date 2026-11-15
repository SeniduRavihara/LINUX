---
name: sinhala-speech-to-text
description: >-
  Transcribes voice notes and audio recordings (WhatsApp voice messages, ogg, opus, mp3, wav, m4a, flac)
  containing Sinhala or multilingual speech into accurate text using the local AGY dictation engine.
  Use when the user asks to transcribe an audio file, convert voice/speech to text, or ingest voice notes into the project.
---

# Sinhala Speech-to-Text Skill

Transcribes audio recordings into Sinhala text using the high-accuracy local AGY speech loop at `/home/senu/PROJECTS/LINUX/scripts/Speech_To_Text_AGY/voice-to-agy.py`.

## Important Rules
- **No File Saving**: Do NOT save the transcript to a file on disk unless the user explicitly asks to save a file. The script processes everything in memory / temp storage.
- **Direct Output**: Output the recognized Sinhala text directly into the chat response for the user.
- **Clipboard**: The script automatically copies the text to the system clipboard (`wl-copy`), so inform the user they can paste (`Ctrl+V`) immediately.
- **No "Saved File" links**: Do not include any "Saved File:" bullet point or disk file links in your response.

## Workflow

### 1. Identify the Audio File
- If the user provided a file path, verify it exists.
- If the user did not provide a path, check `~/Downloads` for recent voice notes or ask the user:
  ```bash
  ls -lt ~/Downloads/*.{ogg,opus,wav,mp3,m4a} 2>/dev/null | head -n 5
  ```

### 2. Execute Transcription
Run the transcription engine with `--no-gui`:
```bash
python3 /home/senu/PROJECTS/LINUX/scripts/Speech_To_Text_AGY/voice-to-agy.py --no-gui "/absolute/path/to/audio/file"
```

### 3. Present the Result
- The command outputs the recognized text between `=== TRANSCRIPT START ===` and `=== TRANSCRIPT END ===`.
- Present the transcribed Sinhala text directly in the chat response.
- Note that it has already been copied to the clipboard.
- Do NOT output any file save path.
