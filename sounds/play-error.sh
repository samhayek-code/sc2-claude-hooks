#!/bin/bash
# Smart error sound wrapper — filters out noise from PostToolUseFailure.
# Reads hook JSON from stdin, then:
#   1. Skips user interrupts (not real errors)
#   2. Enforces a cooldown so errors don't rapid-fire
#   3. Plays a random error sound if checks pass

SOUNDS_DIR="$HOME/.claude/sounds"
COOLDOWN_FILE="/tmp/sc2-claude-last-error"
COOLDOWN_SECONDS=15

# Read the hook JSON from stdin
INPUT=$(cat)

# Skip user interrupts — they canceled something, not a real error
IS_INTERRUPT=$(echo "$INPUT" | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    print(str(d.get('is_interrupt', False)).lower())
except:
    print('false')
" 2>/dev/null)

if [ "$IS_INTERRUPT" = "true" ]; then
  exit 0
fi

# Cooldown: don't play if we played an error sound in the last N seconds
if [ -f "$COOLDOWN_FILE" ]; then
  LAST=$(cat "$COOLDOWN_FILE" 2>/dev/null)
  NOW=$(date +%s)
  if [ -n "$LAST" ] && [ $((NOW - LAST)) -lt "$COOLDOWN_SECONDS" ]; then
    exit 0
  fi
fi

# Record timestamp and play
date +%s > "$COOLDOWN_FILE"
"$SOUNDS_DIR/play-random.sh" "$SOUNDS_DIR/active/error"
