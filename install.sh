#!/bin/bash
# SC2 Claude Hooks — Interactive Installer
# StarCraft 2 sound effects for Claude Code.
# macOS only (uses afplay for audio playback).

set -e

# ── Colors ──────────────────────────────────────────────────────────────────

CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
DIM='\033[2m'
BOLD='\033[1m'
NC='\033[0m'

# ── Print helpers ───────────────────────────────────────────────────────────

print_step()    { echo -e "  ${CYAN}▶${NC} $1"; }
print_success() { echo -e "  ${GREEN}✓${NC} $1"; }
print_warning() { echo -e "  ${YELLOW}⚠${NC} $1"; }
print_error()   { echo -e "  ${RED}✗${NC} $1"; }

# ── Flags ───────────────────────────────────────────────────────────────────

FORCE=false
for arg in "$@"; do
  [ "$arg" = "--force" ] && FORCE=true
done

# ── Header ──────────────────────────────────────────────────────────────────

echo ""
echo -e "${CYAN}  ███████╗ ██████╗ ██████╗ ${NC}"
echo -e "${CYAN}  ██╔════╝██╔════╝ ╚════██╗${NC}"
echo -e "${CYAN}  ███████╗██║       █████╔╝${NC}"
echo -e "${CYAN}  ╚════██║██║      ██╔═══╝ ${NC}"
echo -e "${CYAN}  ███████║╚██████╗ ███████╗${NC}"
echo -e "${CYAN}  ╚══════╝ ╚═════╝ ╚══════╝${NC}"
echo -e "  ${DIM}Sound effects for Claude Code${NC}"
echo ""

# ── Requirements ────────────────────────────────────────────────────────────

print_step "Checking requirements..."

if [[ "$(uname)" == "Darwin" ]]; then
  print_success "macOS detected"
else
  print_warning "Non-macOS detected — afplay won't work"
  echo -e "  ${DIM}  Swap afplay for aplay/paplay/mpv in play-random.sh,${NC}"
  echo -e "  ${DIM}  then re-run with --force${NC}"
  if [ "$FORCE" = false ]; then
    exit 1
  fi
  print_warning "Continuing with --force..."
fi

if command -v python3 &>/dev/null; then
  print_success "python3 found"
else
  print_error "python3 is required (for hooks merge)"
  echo -e "  ${DIM}  Install via: xcode-select --install${NC}"
  exit 1
fi

CLAUDE_DIR="$HOME/.claude"
if [ -d "$CLAUDE_DIR" ]; then
  print_success "Claude Code directory found"
else
  print_warning "~/.claude not found — creating it"
  mkdir -p "$CLAUDE_DIR"
fi

echo ""

# ── Source detection (local repo vs remote curl) ────────────────────────────

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" 2>/dev/null && pwd)"

if [[ -d "$SCRIPT_DIR/sounds/terran" ]]; then
  SOURCE_DIR="$SCRIPT_DIR"
else
  print_step "Downloading from GitHub..."
  SOURCE_DIR=$(mktemp -d)
  trap "rm -rf '$SOURCE_DIR'" EXIT

  curl -fsSL https://github.com/samhayek-code/sc2-claude-hooks/archive/main.tar.gz \
    | tar xz -C "$SOURCE_DIR" --strip-components=1 \
    || { print_error "Download failed"; exit 1; }

  print_success "Downloaded"
  echo ""
fi

# ── Faction picker ──────────────────────────────────────────────────────────

echo -e "  ${CYAN}┌─────────────────────────────────────────────┐${NC}"
echo -e "  ${CYAN}│${NC}  ${BOLD}SELECT YOUR FACTION${NC}                        ${CYAN}│${NC}"
echo -e "  ${CYAN}├─────────────────────────────────────────────┤${NC}"
echo -e "  ${CYAN}│${NC}                                             ${CYAN}│${NC}"
echo -e "  ${CYAN}│${NC}   ${BOLD}[1]${NC} Terran  — ${DIM}\"Battlecruiser operational\"${NC} ${CYAN}│${NC}"
echo -e "  ${CYAN}│${NC}   ${BOLD}[2]${NC} Protoss — ${DIM}\"Carrier has arrived\"${NC}      ${CYAN}│${NC}"
echo -e "  ${CYAN}│${NC}   ${BOLD}[3]${NC} Zerg    — ${DIM}\"Evolution complete\"${NC}        ${CYAN}│${NC}"
echo -e "  ${CYAN}│${NC}                                             ${CYAN}│${NC}"
echo -e "  ${CYAN}└─────────────────────────────────────────────┘${NC}"
echo ""

# Handle interactive vs piped stdin (curl | bash)
if [ -t 0 ]; then
  read -p "  Enter choice [1-3, default=1]: " FACTION_CHOICE
else
  FACTION_CHOICE=$(bash -c 'read -p "  Enter choice [1-3, default=1]: " c < /dev/tty && echo "$c"' 2>/dev/null) || {
    FACTION_CHOICE="1"
    echo -e "  ${DIM}Non-interactive mode — defaulting to Terran${NC}"
  }
fi

case "$FACTION_CHOICE" in
  2) FACTION="protoss" ;;
  3) FACTION="zerg" ;;
  *) FACTION="terran" ;;
esac

echo ""

# ── Paths ───────────────────────────────────────────────────────────────────

SOUNDS_DEST="$CLAUDE_DIR/sounds"
SETTINGS_FILE="$CLAUDE_DIR/settings.json"

# ── Copy sounds ─────────────────────────────────────────────────────────────

print_step "Deploying sounds..."
mkdir -p "$SOUNDS_DEST"

for faction_dir in terran protoss zerg; do
  cp -R "$SOURCE_DIR/sounds/$faction_dir" "$SOUNDS_DEST/"
  count=$(find "$SOUNDS_DEST/$faction_dir" \( -name '*.mp3' -o -name '*.m4a' \) | wc -l | tr -d ' ')
  print_success "$faction_dir ($count sounds)"
done

# ── Install scripts ─────────────────────────────────────────────────────────

print_step "Installing scripts..."
cp "$SOURCE_DIR/sounds/play-random.sh" "$SOUNDS_DEST/"
cp "$SOURCE_DIR/sounds/play-error.sh" "$SOUNDS_DEST/"
cp "$SOURCE_DIR/sounds/set-faction.sh" "$SOUNDS_DEST/"
chmod +x "$SOUNDS_DEST/play-random.sh" "$SOUNDS_DEST/play-error.sh" "$SOUNDS_DEST/set-faction.sh"
print_success "play-random.sh, play-error.sh, set-faction.sh"

# ── Set faction ─────────────────────────────────────────────────────────────

print_step "Setting faction to: $FACTION"
rm -f "$SOUNDS_DEST/active"
ln -s "$SOUNDS_DEST/$FACTION" "$SOUNDS_DEST/active"
print_success "Active faction: $FACTION"

# ── Merge hooks into settings.json ──────────────────────────────────────────

print_step "Configuring hooks..."

mkdir -p "$CLAUDE_DIR"
if [ ! -f "$SETTINGS_FILE" ]; then
  echo "{}" > "$SETTINGS_FILE"
fi

# Back up before modifying
cp "$SETTINGS_FILE" "$SETTINGS_FILE.backup"

python3 << 'PYEOF'
import json, os

settings_path = os.path.expanduser("~/.claude/settings.json")

with open(settings_path, "r") as f:
    settings = json.load(f)

# SC2 hooks — one entry per event type
sc2_hooks = {
    "SessionStart": {
        "hooks": [{"type": "command", "command": "$HOME/.claude/sounds/play-random.sh $HOME/.claude/sounds/active/session-start"}]
    },
    "Stop": {
        "hooks": [{"type": "command", "command": "$HOME/.claude/sounds/play-random.sh $HOME/.claude/sounds/active/task-complete"}]
    },
    "Notification": {
        "matcher": "permission_prompt",
        "hooks": [{"type": "command", "command": "$HOME/.claude/sounds/play-random.sh $HOME/.claude/sounds/active/needs-permission"}]
    },
    "PostToolUseFailure": {
        "matcher": "Bash",
        "hooks": [{"type": "command", "command": "$HOME/.claude/sounds/play-error.sh"}]
    },
}

# Fingerprint: any hook command containing this string is ours
SC2_MARKER = ".claude/sounds/"

existing_hooks = settings.get("hooks", {})

for event, sc2_entry in sc2_hooks.items():
    entries = existing_hooks.get(event, [])

    # Remove any previous SC2 entries (by matching command strings)
    cleaned = []
    for entry in entries:
        cmds = [h.get("command", "") for h in entry.get("hooks", [])]
        if any(SC2_MARKER in cmd for cmd in cmds):
            continue  # drop old SC2 entry
        cleaned.append(entry)

    # Append the current SC2 entry
    cleaned.append(sc2_entry)
    existing_hooks[event] = cleaned

settings["hooks"] = existing_hooks

with open(settings_path, "w") as f:
    json.dump(settings, f, indent=2)
    f.write("\n")
PYEOF

print_success "Hooks merged into settings.json"
print_success "Backed up to settings.json.backup"

# ── Complete ────────────────────────────────────────────────────────────────

echo ""
echo -e "  ${GREEN}╔═════════════════════════════════════════════╗${NC}"
echo -e "  ${GREEN}║${NC}         ${BOLD}INSTALLATION COMPLETE${NC}              ${GREEN}║${NC}"
echo -e "  ${GREEN}╚═════════════════════════════════════════════╝${NC}"

# Faction-specific flavor
case "$FACTION" in
  terran)  echo -e "  ${DIM}\"Adjutant online. All systems nominal.\"${NC}" ;;
  protoss) echo -e "  ${DIM}\"En taro Adun.\"${NC}" ;;
  zerg)    echo -e "  ${DIM}\"The Swarm grows stronger.\"${NC}" ;;
esac

echo ""
echo -e "  ${CYAN}Switch factions:${NC}"
echo "    ~/.claude/sounds/set-faction.sh protoss"
echo ""
echo -e "  ${CYAN}Test it:${NC}"
echo "    ~/.claude/sounds/play-random.sh ~/.claude/sounds/active/session-start"
echo ""
echo -e "  ${CYAN}Add custom sounds:${NC}"
echo "    Drop .mp3/.m4a files into ~/.claude/sounds/<faction>/<event>/"
echo ""
echo -e "  ${CYAN}Uninstall:${NC}"
echo "    ./uninstall.sh"
echo ""
echo -e "  ${DIM}Start a new Claude Code session to hear it.${NC}"
echo ""
