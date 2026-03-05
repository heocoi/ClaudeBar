# Changelog

## [0.1.0] - 2026-03-05

Initial release.

### Added
- Menu bar icon with status indicator (idle/attention)
- Unix socket server at `/tmp/claudebar.sock` for receiving Claude Code hook events
- Permission prompt view with Allow/Deny buttons and command preview
- Question view with option buttons for AskUserQuestion events
- Text input view for general prompts
- Kitty terminal adapter using `kitten @` remote control
- Window ID targeting — responses go to the exact kitty window running Claude Code
- Generic terminal adapter for iTerm2, Terminal.app, and WezTerm (AppleScript)
- Hook script with `KITTY_WINDOW_ID` injection and fallback to macOS notification
- Settings: terminal selection, auto-popup toggle, sound toggle
- Auto-popup on incoming events
- Sound notification (Ping) on new events
