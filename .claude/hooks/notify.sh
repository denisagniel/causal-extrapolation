#!/bin/bash
# macOS desktop notification when the agent needs attention
# Triggers on: permission prompts, idle prompts, auth events
INPUT=$(cat)
MESSAGE=$(echo "$INPUT" | jq -r '.message // "Agent needs attention"')
TITLE=$(echo "$INPUT" | jq -r '.title // "AI coding agent"')
osascript -e "display notification \"$MESSAGE\" with title \"$TITLE\"" 2>/dev/null
exit 0
