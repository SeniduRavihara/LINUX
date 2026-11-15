#!/usr/bin/env python3
"""Transcribe a chosen audio file using AGY's speech dictation and save the text."""
import os, sys, subprocess as sp, tempfile, pathlib, shutil, pty, select, time, re, termios, tty, signal, fcntl, wave, array, datetime, shlex

def run(*args, **kw):
    return sp.run(args, check=True, **kw)

def copy_to_clipboard(text):
    """Copies text to system clipboard using wl-copy, xclip, xsel, or tkinter."""
    # 1. Try wl-copy (Wayland native)
    if shutil.which('wl-copy'):
        try:
            p = sp.Popen(['wl-copy'], stdin=sp.PIPE)
            p.communicate(input=text.encode('utf-8'))
            if p.returncode == 0:
                return True
        except Exception:
            pass

    # 2. Try xclip (X11)
    if shutil.which('xclip'):
        try:
            p = sp.Popen(['xclip', '-selection', 'clipboard'], stdin=sp.PIPE)
            p.communicate(input=text.encode('utf-8'))
            if p.returncode == 0:
                return True
        except Exception:
            pass

    # 3. Try xsel (X11)
    if shutil.which('xsel'):
        try:
            p = sp.Popen(['xsel', '--clipboard', '--input'], stdin=sp.PIPE)
            p.communicate(input=text.encode('utf-8'))
            if p.returncode == 0:
                return True
        except Exception:
            pass

    # 4. Try tkinter
    try:
        import tkinter as tk
        r = tk.Tk()
        r.withdraw()
        r.clipboard_clear()
        r.clipboard_append(text)
        r.update()
        r.destroy()
        return True
    except Exception:
        pass

    return False

def show_transcript_dialog(output_path):
    """Displays a graphical window with the transcript and a prominent Copy button."""
    output_path = pathlib.Path(output_path)
    if not output_path.exists():
        return
    text = output_path.read_text(encoding='utf-8')
    copy_to_clipboard(text)

    # 1. Try modern Libadwaita / GTK4 UI (native GNOME look with Copy button and toast)
    try:
        import gi
        gi.require_version('Gtk', '4.0')
        gi.require_version('Adw', '1')
        from gi.repository import Gtk, Adw, GLib

        app = Adw.Application(application_id=f'com.senu.speechtotext.viewer{os.getpid()}')

        def on_activate(app):
            win = Adw.ApplicationWindow(application=app, title='Sinhala transcript — saved')
            win.set_default_size(860, 620)

            box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL)

            # Header bar with document title and Copy button
            header = Adw.HeaderBar()
            title_widget = Adw.WindowTitle(title='Sinhala transcript — saved', subtitle=output_path.name)
            header.set_title_widget(title_widget)

            copy_btn = Gtk.Button(label=' Copy Text')
            copy_btn.set_icon_name('edit-copy-symbolic')
            copy_btn.add_css_class('suggested-action')
            header.pack_end(copy_btn)

            box.append(header)

            toast_overlay = Adw.ToastOverlay()

            text_view = Gtk.TextView()
            text_view.set_wrap_mode(Gtk.WrapMode.WORD)
            text_view.set_editable(True)
            text_view.set_left_margin(20)
            text_view.set_right_margin(20)
            text_view.set_top_margin(20)
            text_view.set_bottom_margin(20)
            buffer = text_view.get_buffer()
            buffer.set_text(text)

            scrolled = Gtk.ScrolledWindow()
            scrolled.set_vexpand(True)
            scrolled.set_child(text_view)
            toast_overlay.set_child(scrolled)

            def do_copy(_):
                current_text = buffer.get_text(buffer.get_start_iter(), buffer.get_end_iter(), True)
                copy_to_clipboard(current_text)
                win.get_clipboard().set(current_text)
                toast_overlay.add_toast(Adw.Toast.new('Copied to clipboard!'))

            copy_btn.connect('clicked', do_copy)

            box.append(toast_overlay)
            win.set_content(box)
            win.present()

        app.connect('activate', on_activate)
        app.run(None)
        return
    except Exception:
        pass

    # 2. Fallback to Zenity with extra Copy button
    if shutil.which('zenity'):
        while True:
            res = sp.run([
                'zenity', '--text-info',
                '--title=Sinhala transcript — saved',
                '--width=850', '--height=600',
                '--editable',
                '--extra-button=Copy to Clipboard',
                '--ok-label=Close',
                '--cancel-label=Close',
                f'--filename={output_path}'
            ], capture_output=True, text=True)

            if 'Copy' in res.stdout or 'Copy' in res.stderr:
                copy_to_clipboard(text)
                if shutil.which('notify-send'):
                    sp.run(['notify-send', '-i', 'edit-copy', 'Sinhala Transcript', 'Copied to clipboard!'], check=False)
                continue
            break

def split_audio(source, folder):
    """Cut at a quiet window near 25 seconds, with no missing audio frames."""
    with wave.open(str(source), 'rb') as src:
        rate = src.getframerate()
        samples = array.array('h', src.readframes(src.getnframes()))
    if sys.byteorder != 'little':
        samples.byteswap()
    chunks = []
    start = 0
    width = rate // 10  # 100ms window for silence check
    while start < len(samples):
        end = min(start + 30 * rate, len(samples))
        if end < len(samples):
            candidates = range(start + 20 * rate, end - width, width)
            quiet = min(candidates, key=lambda n: sum(x * x for x in samples[n:n + width]))
            end = quiet + width // 2
        dest = folder / f'part-{len(chunks) + 1:03}.wav'
        piece = samples[start:end]
        if sys.byteorder != 'little':
            piece.byteswap()
        with wave.open(str(dest), 'wb') as out:
            out.setnchannels(1)
            out.setsampwidth(2)
            out.setframerate(rate)
            out.writeframes(piece.tobytes())
        chunks.append(dest)
        start = end
    if not chunks:
        raise RuntimeError('The recording is empty.')
    return chunks

def main():
    for name in ('agy', 'pw-record', 'pactl', 'paplay', 'ffmpeg', 'zenity'):
        if not shutil.which(name):
            raise RuntimeError(f'Missing required program: {name}')

    no_gui = '--no-gui' in sys.argv
    cli_args = [a for a in sys.argv[1:] if a != '--no-gui']

    if len(cli_args) > 0:
        audio = cli_args[0]
        # Allow passing existing transcript to view/copy
        if audio.endswith('.txt') and pathlib.Path(audio).is_file():
            show_transcript_dialog(audio)
            return
    else:
        res = sp.run([
            'zenity', '--file-selection',
            '--title=Choose a voice message to transcribe',
            f'--filename={pathlib.Path.home()}/Downloads/',
            '--file-filter=Audio files | *.ogg *.opus *.wav *.mp3 *.m4a *.flac *.aac *.wma',
            '--file-filter=All files | *'
        ], capture_output=True, text=True)
        audio = res.stdout.strip()

    if not audio:
        return

    if not pathlib.Path(audio).is_file():
        raise RuntimeError(f'Audio file not found: {audio}')

    modules = []
    player = None
    child = None
    master = None
    terminal = None
    old = None

    try:
        if os.isatty(sys.stdin.fileno()):
            terminal = os.open('/dev/tty', os.O_RDWR)
    except OSError:
        terminal = None

    def tty_write(msg):
        if terminal is not None:
            try:
                if isinstance(msg, str):
                    msg = msg.encode('utf-8', 'replace')
                os.write(terminal, msg)
            except OSError:
                pass
        else:
            if isinstance(msg, bytes):
                msg = msg.decode('utf-8', 'replace')
            sys.stdout.write(msg)
            sys.stdout.flush()

    with tempfile.TemporaryDirectory(prefix='agy-voice-') as folder:
        folder = pathlib.Path(folder)
        try:
            print(f'Preparing recording: {pathlib.Path(audio).name}...', flush=True)
            run('ffmpeg', '-nostdin', '-hide_banner', '-loglevel', 'error', '-y',
                '-i', audio, '-vn', '-ac', '1', '-ar', '16000', str(folder / 'message.wav'))

            chunks = split_audio(folder / 'message.wav', folder)
            output_dir = pathlib.Path(__file__).resolve().parent / 'transcripts'
            output_dir.mkdir(exist_ok=True)
            stamp = datetime.datetime.now().strftime('%Y%m%d-%H%M%S')
            output = output_dir / (pathlib.Path(audio).stem + '-' + stamp + '.txt')
            partial = output.with_suffix('.partial.txt')

            config = folder / 'save-target'
            saved = folder / 'saved.txt'
            config.write_text(str(saved))

            editor = folder / 'save-prompt.py'
            editor.write_text(
                '#!' + sys.executable + '\n'
                'import sys, pathlib\n'
                'p = pathlib.Path(sys.argv[1])\n'
                'target = pathlib.Path(' + repr(str(config)) + ').read_text()\n'
                'text = p.read_text()\n'
                'p.write_text("")\n'
                'tmp = pathlib.Path(target + ".tmp")\n'
                'tmp.write_text(text)\n'
                'tmp.replace(target)\n'
            )
            editor.chmod(0o755)

            pid = os.getpid()
            sink = f'agy_file_{pid}'
            mic = f'agy_mic_{pid}'

            sink_mod = run('pactl', 'load-module', 'module-null-sink', f'sink_name={sink}',
                           capture_output=True, text=True).stdout.strip()
            modules.append(sink_mod)

            mic_mod = run('pactl', 'load-module', 'module-remap-source',
                          f'master={sink}.monitor', f'source_name={mic}',
                          'source_properties=device.description=AGY_Voice_Microphone',
                          capture_output=True, text=True).stdout.strip()
            modules.append(mic_mod)

            recorder = shutil.which('pw-record')
            wrapper = folder / 'pw-record'
            wrapper.write_text(f'#!/bin/sh\nexec {shlex.quote(recorder)} --target={shlex.quote(mic)} "$@"\n')
            wrapper.chmod(0o755)

            child, master = pty.fork()
            if child == 0:
                os.environ['PATH'] = str(folder) + os.pathsep + os.environ.get('PATH', '')
                os.environ['PULSE_SOURCE'] = mic
                os.environ['EDITOR'] = str(editor)
                os.environ['VISUAL'] = str(editor)
                os.environ['TERM'] = 'xterm-256color'
                os.execvp('agy', ['agy'])

            def resize(*_):
                if terminal is not None and master is not None:
                    try:
                        fcntl.ioctl(master, termios.TIOCSWINSZ, fcntl.ioctl(terminal, termios.TIOCGWINSZ, b'\0' * 8))
                    except OSError:
                        pass

            if terminal is not None:
                old = termios.tcgetattr(terminal)
                resize()
                signal.signal(signal.SIGWINCH, resize)
                tty.setraw(terminal)

            part = 0
            attempts = 0
            collected = []
            seen = ''
            stage = 'starting'
            ready_at = None
            stop_at = None
            finalize_start = None
            saw_finishing = False
            export_at = None
            export_deadline = None
            settle_until = None
            started = time.monotonic()

            tty_write('\r\nOpening AGY. Dictation and playback will start automatically.\r\n')

            while True:
                now = time.monotonic()
                r_list = [master]
                if terminal is not None:
                    r_list.append(terminal)

                readable, _, _ = select.select(r_list, [], [], 0.1)

                if master in readable:
                    try:
                        data = os.read(master, 65536)
                    except OSError:
                        break
                    if not data:
                        break
                    tty_write(data)
                    seen = (seen + data.decode('utf-8', 'replace'))[-24000:]
                    clean = re.sub(r'\x1b\[[0-?]*[ -/]*[@-~]', '', seen)

                    if stage == 'starting' and ('for shortcuts' in clean or '> ' in clean or 'Gemini' in clean):
                        if ready_at is None:
                            ready_at = now + 1.0

                    if stage == 'waiting' and ('Recording' in clean or 'recording' in clean.lower()):
                        stage = 'playing'
                        seen = ''
                        # Allow PipeWire audio pipeline to settle before playing
                        time.sleep(0.5)
                        player = sp.Popen(['paplay', f'--device={sink}', str(chunks[part])])

                    if stage == 'waiting_finalize':
                        if 'Finishing up' in clean:
                            saw_finishing = True

                if terminal is not None and terminal in readable:
                    data = os.read(terminal, 4096)
                    if not data:
                        break
                    if b'\x03' in data:  # Ctrl+C
                        raise KeyboardInterrupt
                    os.write(master, data)

                # STAGE: starting -> wait until AGY prompt is ready, then trigger /voice dictate
                if stage == 'starting' and ready_at and now >= ready_at:
                    tty_write(f'\r\nTranscribing section {part + 1}/{len(chunks)}...\r\n')
                    os.write(master, b'\x15/voice dictate\r')
                    stage = 'waiting'
                    seen = ''
                    started = now

                # STAGE: waiting -> timeout if dictation takes too long to enter recording mode
                if stage == 'waiting' and (now - started > 30):
                    attempts += 1
                    if attempts > 3:
                        raise RuntimeError(f'AGY did not start dictation for section {part + 1} after 3 attempts.')
                    tty_write(b'\r\nDictation took too long to start, retrying...\r\n')
                    os.write(master, b'\x03\x15')
                    stage = 'settling'
                    settle_until = now + 2.0

                # STAGE: playing -> wait until audio playback finishes
                if stage == 'playing' and player is not None and player.poll() is not None:
                    if player.returncode != 0:
                        raise RuntimeError(f'Audio playback failed with exit code {player.returncode}')
                    # Playback done. Allow 2.0s buffer flush and cloud processing before sending F5
                    stage = 'playback_done'
                    stop_at = now + 2.0

                # STAGE: playback_done -> send F5 to signal end of dictation
                if stage == 'playback_done' and now >= stop_at:
                    os.write(master, b'\x1b[15~')  # F5
                    stage = 'waiting_finalize'
                    finalize_start = now
                    saw_finishing = False
                    seen = ''

                # STAGE: waiting_finalize -> wait for "Finishing up..." to conclude and prompt return
                if stage == 'waiting_finalize':
                    # Finishing up concluded when it disappears after having been seen, or after timeout
                    if (saw_finishing and 'Finishing up' not in clean) or (now - finalize_start >= 5.5):
                        stage = 'exporting'
                        export_at = now + 0.5
                        export_deadline = now + 20.0
                        seen = ''

                # STAGE: exporting -> trigger $EDITOR via Ctrl+G and read captured text
                if stage == 'exporting':
                    if saved.exists():
                        text = saved.read_text().strip()
                        try:
                            saved.unlink()
                        except OSError:
                            pass

                        if text:
                            # Successful capture!
                            collected.append(text)
                            partial.write_text('\n\n'.join(collected) + '\n', encoding='utf-8')
                            part += 1
                            attempts = 0
                            tty_write(f'\r\nSection {part}/{len(chunks)} completed.\r\n')
                        else:
                            # Empty text (silence or dropped audio)
                            attempts += 1
                            if attempts < 2:
                                tty_write(b'\r\nNo speech captured in this section, retrying once...\r\n')
                            else:
                                tty_write(b'\r\n[Section contained no detectable speech - advancing]\r\n')
                                part += 1
                                attempts = 0

                        if part == len(chunks):
                            if partial.exists():
                                partial.replace(output)
                            tty_write(f'\r\nTRANSCRIPTION COMPLETE: {output}\r\n')
                            # Exit AGY session cleanly
                            os.write(master, b'/exit\r')
                            time.sleep(1.0)
                            break

                        # Transition to settling before next section
                        stage = 'settling'
                        settle_until = now + 2.0
                        seen = ''

                    elif now >= export_deadline:
                        raise RuntimeError(f'AGY timed out exporting section {part + 1}. Partial text saved in: {partial}')
                    elif now >= export_at:
                        os.write(master, b'\x07')  # Ctrl+G opens prompt in editor
                        export_at = now + 3.5

                # STAGE: settling -> allow AGY TUI to settle into idle state before next dictation
                if stage == 'settling' and now >= settle_until:
                    os.write(master, b'\x15')  # Ctrl+U to clear any leftover characters
                    time.sleep(0.3)
                    tty_write(f'\r\nTranscribing section {part + 1}/{len(chunks)}...\r\n')
                    os.write(master, b'/voice dictate\r')
                    stage = 'waiting'
                    seen = ''
                    started = now

        finally:
            if old is not None and terminal is not None:
                termios.tcsetattr(terminal, termios.TCSADRAIN, old)

            if player is not None and player.poll() is None:
                player.terminate()
                try:
                    player.wait(timeout=1)
                except sp.TimeoutExpired:
                    player.kill()

            if child:
                try:
                    if master is not None:
                        try:
                            os.write(master, b'\x03/exit\r')
                        except OSError:
                            pass
                    os.kill(child, signal.SIGTERM)
                    for _ in range(20):
                        pid, _ = os.waitpid(child, os.WNOHANG)
                        if pid == child:
                            break
                        time.sleep(0.1)
                    else:
                        os.kill(child, signal.SIGKILL)
                        os.waitpid(child, 0)
                except (ProcessLookupError, ChildProcessError):
                    pass

            if master is not None:
                try:
                    os.close(master)
                except OSError:
                    pass

            if terminal is not None:
                try:
                    os.close(terminal)
                except OSError:
                    pass

            for module in reversed(modules):
                sp.run(['pactl', 'unload-module', module], stdout=sp.DEVNULL, stderr=sp.DEVNULL)

    if 'output' in locals() and output.exists():
        text_content = output.read_text(encoding='utf-8')
        print(f'\nTranscription successfully saved:\n{output}\n')
        # Automatically copy to clipboard
        copy_to_clipboard(text_content)
        print('Copied to system clipboard!')
        print('\n=== TRANSCRIPT START ===')
        print(text_content)
        print('=== TRANSCRIPT END ===\n')
        # Display GUI viewer dialog with prominent Copy button unless --no-gui requested
        if not no_gui:
            show_transcript_dialog(output)

if __name__ == '__main__':
    try:
        main()
    except KeyboardInterrupt:
        print('\nOperation cancelled by user.')
    except Exception as e:
        print(f'\nVoice to AGY Error: {e}', file=sys.stderr)
        sys.exit(1)
