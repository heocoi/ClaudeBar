# ClaudeBar

macOS menu bar companion for [Claude Code](https://docs.anthropic.com/en/docs/claude-code). Respond to permissions, questions, and prompts without switching to your terminal.

## The Problem

Claude Code runs in the terminal. When it needs your input (permission to run a command, a question, idle prompt), you have to switch to the terminal, find the right window, and respond. This breaks your flow.

## How It Works

```
Claude Code (hook) → ClaudeBar (menu bar popup) → You (click Allow) → Terminal (receives "y" + Enter)
```

ClaudeBar listens for Claude Code hook events via Unix socket. When Claude needs attention, a popup appears on your menu bar with context and quick actions. Your response is sent directly to the correct terminal window — no context switching needed.

## Features

- **Permission prompts** — Allow/Deny buttons with command preview
- **Questions** — Option buttons for AskUserQuestion events
- **Text input** — Free-form input field for general prompts
- **Window targeting** — Sends responses to the exact terminal window running Claude Code (not just the focused one)
- **Sound notifications** — Ping sound when Claude needs attention
- **Auto-popup** — Popup appears automatically on new events

### Terminal Support

| Terminal | Status | Method |
|----------|--------|--------|
| Kitty | Full support | `kitten @` remote control |
| iTerm2 | Basic | AppleScript |
| Terminal.app | Basic | AppleScript |
| WezTerm | Basic | `wezterm cli` |

Kitty is recommended — it supports window ID targeting for accurate delivery.

## Setup

### Requirements

- macOS 14 Sonoma or later
- Xcode 16+ (to build)
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) (optional, for regenerating xcodeproj)

### Build & Run

```bash
cd ClaudeBar
xcodebuild -scheme ClaudeBar -configuration Debug build
open ~/Library/Developer/Xcode/DerivedData/ClaudeBar-*/Build/Products/Debug/ClaudeBar.app
```

Or open `ClaudeBar.xcodeproj` in Xcode and hit Run.

### Install Hook

Copy the hook script and add it to your Claude Code settings:

```bash
cp ClaudeBar/Hook/notify-claudebar.sh ~/.claude/hooks/notify-claudebar.sh
chmod +x ~/.claude/hooks/notify-claudebar.sh
```

Add to `~/.claude/settings.json`:

```json
{
  "hooks": {
    "Notification": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "~/.claude/hooks/notify-claudebar.sh"
          }
        ]
      }
    ]
  }
}
```

### Kitty Setup

For window-targeted responses, enable remote control in `kitty.conf`:

```
allow_remote_control yes
listen_on unix:/tmp/kitty-{kitty_pid}
```

Restart kitty after changing the config.

## Architecture

```
~/.claude/hooks/notify-claudebar.sh
  ↓ (reads stdin JSON from Claude Code, injects KITTY_WINDOW_ID)
Unix socket /tmp/claudebar.sock
  ↓
SocketServer → EventParser → SessionManager
  ↓
PopoverView (PermissionView / QuestionView / InputView)
  ↓ (user clicks Allow / selects option / types response)
TerminalAdapter (KittyAdapter / GenericTerminalAdapter)
  ↓
kitten @ send-text + send-key Return → correct terminal window
```

## Roadmap

- [ ] Auto-dismiss popup after timeout
- [ ] Global keyboard shortcut to toggle popup
- [ ] Notification history
- [ ] Multiple concurrent Claude Code sessions
- [ ] tmux adapter

## License

MIT
