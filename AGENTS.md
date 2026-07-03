# Tiny Horse Ranch - Codex Instructions

This is a Godot 4.7 project.

Never run `godot` or `godot.exe`.

In this Windows environment, `godot` resolves to `godot.exe`, and `godot.exe` crashes with a Win32 memory read error.

Use only `godot_console`.

Forbidden commands:
- godot
- godot.exe
- godot --path .
- godot -e
- godot --headless --path . --quit
- godot --headless

Allowed validation command:
- powershell -ExecutionPolicy Bypass -File .\tools\check-godot.ps1

Do not run full project execution validation.
Do not run GUI/editor validation from Codex.
The user will manually test gameplay with F5 in the Godot editor.

After code changes:
1. Run only .\tools\check-godot.ps1
2. Report whether it passed
3. Tell the user what to manually test in Godot
