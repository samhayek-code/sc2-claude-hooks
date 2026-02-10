#!/bin/bash
# SC2 Claude Hooks — Installer
# Copies sound files and configures Claude Code hooks for StarCraft 2 sound effects.
# macOS only (uses afplay for audio playback).

set -e

# -- Sanity checks ----------------------------------------------------------

if [[ "$(uname)" != "Darwin" ]]; then
  echo "Warning: This installer is built for macOS (uses afplay)."
  echo "On Linux, you'd need to swap afplay for aplay/paplay/mpv."
  echo "Continuing anyway — sounds won't play until you patch play-random.sh."
fi

if ! command -v python3 &>/dev/null; then
  echo "Error: python3 is required to merge hooks into settings.json."
  echo "Install it via Xcode Command Line Tools: xcode-select --install"
  exit 1
fi

# -- Paths -------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CLAUDE_DIR="$HOME/.claude"
SOUNDS_DEST="$CLAUDE_DIR/sounds"
SETTINGS_FILE="$CLAUDE_DIR/settings.json"

# -- Copy sounds -------------------------------------------------------------

echo "Copying sounds to $SOUNDS_DEST..."
mkdir -p "$SOUNDS_DEST"

# Copy faction dirs and scripts (overwrite existing)
cp -R "$SCRIPT_DIR/sounds/terran" "$SOUNDS_DEST/"
cp -R "$SCRIPT_DIR/sounds/protoss" "$SOUNDS_DEST/"
cp -R "$SCRIPT_DIR/sounds/zerg" "$SOUNDS_DEST/"
cp "$SCRIPT_DIR/sounds/play-random.sh" "$SOUNDS_DEST/"
cp "$SCRIPT_DIR/sounds/set-faction.sh" "$SOUNDS_DEST/"

# Make scripts executable
chmod +x "$SOUNDS_DEST/play-random.sh" "$SOUNDS_DEST/set-faction.sh"

# Create active symlink (default: terran) if it doesn't exist
if [ ! -L "$SOUNDS_DEST/active" ]; then
  ln -s "$SOUNDS_DEST/terran" "$SOUNDS_DEST/active"
  echo "Default faction set to: terran"
else
  CURRENT=$(readlink "$SOUNDS_DEST/active" | xargs basename)
  echo "Keeping existing faction: $CURRENT"
fi

# -- Merge hooks into settings.json -----------------------------------------

echo "Configuring Claude Code hooks..."

# Ensure settings file exists
mkdir -p "$CLAUDE_DIR"
if [ ! -f "$SETTINGS_FILE" ]; then
  echo "{}" > "$SETTINGS_FILE"
fi

# Back up existing settings
cp "$SETTINGS_FILE" "$SETTINGS_FILE.backup"
echo "Backed up settings to $SETTINGS_FILE.backup"

# Use python3 to safely deep-merge hooks into existing settings
python3 << 'PYEOF'
import json, sys, os

settings_path = os.path.expanduser("~/.claude/settings.json")
hooks_path = os.path.join(os.path.dirname(os.path.abspath(sys.argv[0] if len(sys.argv) > 0 else ".")), "hooks.json")

# Read existing settings
with open(settings_path, "r") as f:
    settings = json.load(f)

# The hooks config to merge
hooks = {
    "SessionStart": [
        {
            "hooks": [
                {
                    "type": "command",
                    "command": "$HOME/.claude/sounds/play-random.sh $HOME/.claude/sounds/active/session-start"
                }
            ]
        }
    ],
    "Stop": [
        {
            "hooks": [
                {
                    "type": "command",
                    "command": "$HOME/.claude/sounds/play-random.sh $HOME/.claude/sounds/active/task-complete"
                }
            ]
        }
    ],
    "Notification": [
        {
            "matcher": "permission_prompt",
            "hooks": [
                {
                    "type": "command",
                    "command": "$HOME/.claude/sounds/play-random.sh $HOME/.claude/sounds/active/needs-permission"
                }
            ]
        }
    ],
    "PostToolUseFailure": [
        {
            "hooks": [
                {
                    "type": "command",
                    "command": "$HOME/.claude/sounds/play-random.sh $HOME/.claude/sounds/active/error"
                }
            ]
        }
    ]
}

# Merge — replace the hooks key entirely (our hooks are the full set)
settings["hooks"] = hooks

with open(settings_path, "w") as f:
    json.dump(settings, f, indent=2)
    f.write("\n")

print("Hooks configured successfully.")
PYEOF

# -- Done --------------------------------------------------------------------

echo ""
echo "============================================"
echo "  SC2 Claude Hooks installed successfully!"
echo "============================================"
echo ""
echo "  Sounds: $SOUNDS_DEST/"
echo "  Hooks:  $SETTINGS_FILE"
echo ""
echo "  Switch factions:"
echo "    $SOUNDS_DEST/set-faction.sh terran"
echo "    $SOUNDS_DEST/set-faction.sh protoss"
echo "    $SOUNDS_DEST/set-faction.sh zerg"
echo ""
echo "  Test it:"
echo "    $SOUNDS_DEST/play-random.sh $SOUNDS_DEST/active/session-start"
echo ""
echo "  Start a new Claude Code session to hear it in action."
echo ""
