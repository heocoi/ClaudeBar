#!/bin/bash
# ClaudeBar Hook Script
# Pipe Claude Code hook events to ClaudeBar via Unix socket.
# Fallback to native macOS notification if socket is unavailable.
#
# Usage in ~/.claude/settings.json:
# {
#   "hooks": {
#     "Notification": [{ "type": "command", "command": "/path/to/notify-claudebar.sh" }],
#     "Stop": [{ "type": "command", "command": "/path/to/notify-claudebar.sh" }]
#   }
# }

INPUT=$(cat)
echo "$INPUT" | socat - UNIX-CONNECT:/tmp/claudebar.sock 2>/dev/null

if [ $? -ne 0 ]; then
    # Socket unavailable — fallback to native notification
    MESSAGE=$(echo "$INPUT" | /usr/bin/python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    print(data.get('message', data.get('last_assistant_message', 'Buddy needs attention'))[:200])
except:
    print('Buddy needs attention')
" 2>/dev/null)
    osascript -e "display notification \"$MESSAGE\" with title \"Claude Code\" sound name \"Ping\""
fi
