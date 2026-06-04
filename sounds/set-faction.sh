#!/bin/bash
# Switch the active sound faction for Claude Code hooks.
# Usage: set-faction.sh <faction>
# Any subdirectory of $SOUNDS_DIR (except the 'active' symlink and _-prefixed dirs) is a valid faction.

SOUNDS_DIR="$HOME/.claude/sounds"
FACTION="$(echo "$1" | tr '[:upper:]' '[:lower:]')"

# Collect available factions: real dirs, excluding the 'active' symlink and _-prefixed helpers.
available=()
for d in "$SOUNDS_DIR"/*/; do
  name="$(basename "$d")"
  [ -L "${d%/}" ] && continue              # skip the 'active' symlink
  [ "${name#_}" != "$name" ] && continue   # skip _incoming and other _-prefixed dirs
  available+=("$name")
done

valid=0
for f in "${available[@]}"; do
  [ "$f" = "$FACTION" ] && valid=1
done

if [ "$valid" -ne 1 ]; then
  echo "Usage: set-faction.sh <faction>"
  echo "Available: ${available[*]}"
  echo "Current:   $(basename "$(readlink "$SOUNDS_DIR/active" 2>/dev/null)" 2>/dev/null || echo 'none')"
  exit 1
fi

# Remove old symlink and create new one
rm -f "$SOUNDS_DIR/active"
ln -s "$SOUNDS_DIR/$FACTION" "$SOUNDS_DIR/active"
echo "Active faction set to: $FACTION"
