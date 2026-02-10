#!/bin/bash
# Switch the active sound faction for Claude Code hooks.
# Usage: set-faction.sh <terran|protoss>

SOUNDS_DIR="$HOME/.claude/sounds"
FACTION="$(echo "$1" | tr '[:upper:]' '[:lower:]')"

if [ "$FACTION" != "terran" ] && [ "$FACTION" != "protoss" ]; then
  echo "Usage: set-faction.sh <terran|protoss>"
  echo "Current: $(readlink "$SOUNDS_DIR/active" 2>/dev/null || echo 'none')"
  exit 1
fi

# Remove old symlink and create new one
rm -f "$SOUNDS_DIR/active"
ln -s "$SOUNDS_DIR/$FACTION" "$SOUNDS_DIR/active"
echo "Active faction set to: $FACTION"
