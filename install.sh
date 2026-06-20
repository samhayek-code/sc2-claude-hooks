#!/bin/bash
# Claude Audio Hooks — Interactive Installer
# Game voice-line sound packs for Claude Code event hooks.
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

# ── Pack catalog (parallel arrays — macOS bash 3.2 compatible) ───────────────
# Order defines the menu numbering. All packs are deployed; the pick only sets
# the starting active pack. set-faction.sh switches between them afterward.

PACKS=(terran protoss zerg cortana guilty-spark sergeant-johnson gdi nod)
PACK_GAMES=("StarCraft 2" "StarCraft 2" "StarCraft 2" "Halo" "Halo" "Halo" "Tiberian Sun" "Tiberian Sun")
PACK_TAGS=(
  "Terran  — \"Battlecruiser operational\""
  "Protoss — \"Carrier has arrived\""
  "Zerg    — \"Evolution complete\""
  "Cortana — \"I've got it under control\""
  "Guilty Spark — \"Greetings\""
  "Sgt. Johnson — \"Oorah!\""
  "GDI / EVA — \"Construction complete\""
  "Nod / CABAL — \"By your command\""
)

# ── Flags ───────────────────────────────────────────────────────────────────

FORCE=false
for arg in "$@"; do
  [ "$arg" = "--force" ] && FORCE=true
done

# ── Header ──────────────────────────────────────────────────────────────────

echo ""
echo -e "${CYAN}  ▟▙ Claude Audio Hooks${NC}"
echo -e "  ${DIM}Game voice lines for Claude Code — StarCraft 2 · Halo · Tiberian Sun${NC}"
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

  curl -fsSL https://github.com/samhayek-code/claude-audio-hooks/archive/main.tar.gz \
    | tar xz -C "$SOURCE_DIR" --strip-components=1 \
    || { print_error "Download failed"; exit 1; }

  print_success "Downloaded"
  echo ""
fi

# ── Pack picker ─────────────────────────────────────────────────────────────

echo -e "  ${CYAN}┌──────────────────────────────────────────────────────┐${NC}"
echo -e "  ${CYAN}│${NC}  ${BOLD}PICK A STARTING VOICE${NC}  ${DIM}(all packs install; switch later)${NC}  ${CYAN}│${NC}"
echo -e "  ${CYAN}└──────────────────────────────────────────────────────┘${NC}"
echo ""
prev_game=""
i=0
while [ $i -lt ${#PACKS[@]} ]; do
  game="${PACK_GAMES[$i]}"
  if [ "$game" != "$prev_game" ]; then
    echo -e "  ${DIM}${game}${NC}"
    prev_game="$game"
  fi
  echo -e "    ${BOLD}[$((i + 1))]${NC} ${PACK_TAGS[$i]}"
  i=$((i + 1))
done
echo ""

# Handle interactive vs piped stdin (curl | bash)
if [ -t 0 ]; then
  read -p "  Enter choice [1-${#PACKS[@]}, default=1]: " PACK_CHOICE
else
  PACK_CHOICE=$(bash -c 'read -p "  Enter choice [1-8, default=1]: " c < /dev/tty && echo "$c"' 2>/dev/null) || {
    PACK_CHOICE="1"
    echo -e "  ${DIM}Non-interactive mode — defaulting to Terran${NC}"
  }
fi

# Validate: numeric and within range, else default to first pack
case "$PACK_CHOICE" in
  ''|*[!0-9]*) PACK_CHOICE=1 ;;
esac
if [ "$PACK_CHOICE" -lt 1 ] || [ "$PACK_CHOICE" -gt ${#PACKS[@]} ]; then
  PACK_CHOICE=1
fi
ACTIVE_PACK="${PACKS[$((PACK_CHOICE - 1))]}"

echo ""

# ── Paths ───────────────────────────────────────────────────────────────────

SOUNDS_DEST="$CLAUDE_DIR/sounds"
SETTINGS_FILE="$CLAUDE_DIR/settings.json"

# ── Copy sounds (all packs) ─────────────────────────────────────────────────

print_step "Deploying sounds..."
mkdir -p "$SOUNDS_DEST"

for pack in "${PACKS[@]}"; do
  [ -d "$SOURCE_DIR/sounds/$pack" ] || continue
  cp -R "$SOURCE_DIR/sounds/$pack" "$SOUNDS_DEST/"
  count=$(find "$SOUNDS_DEST/$pack" \( -name '*.mp3' -o -name '*.m4a' \) | wc -l | tr -d ' ')
  print_success "$pack ($count sounds)"
done

# ── Install scripts ─────────────────────────────────────────────────────────

print_step "Installing scripts..."
cp "$SOURCE_DIR/sounds/play-random.sh" "$SOUNDS_DEST/"
cp "$SOURCE_DIR/sounds/play-error.sh" "$SOUNDS_DEST/"
cp "$SOURCE_DIR/sounds/set-faction.sh" "$SOUNDS_DEST/"
chmod +x "$SOUNDS_DEST/play-random.sh" "$SOUNDS_DEST/play-error.sh" "$SOUNDS_DEST/set-faction.sh"
print_success "play-random.sh, play-error.sh, set-faction.sh"

# ── Set active pack ─────────────────────────────────────────────────────────

print_step "Setting active voice to: $ACTIVE_PACK"
rm -f "$SOUNDS_DEST/active"
ln -s "$SOUNDS_DEST/$ACTIVE_PACK" "$SOUNDS_DEST/active"
print_success "Active voice: $ACTIVE_PACK"

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

# Event hooks — one entry per event type
audio_hooks = {
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
MARKER = ".claude/sounds/"

existing_hooks = settings.get("hooks", {})

for event, entry in audio_hooks.items():
    entries = existing_hooks.get(event, [])

    # Remove any previous entries of ours (by matching command strings)
    cleaned = []
    for e in entries:
        cmds = [h.get("command", "") for h in e.get("hooks", [])]
        if any(MARKER in cmd for cmd in cmds):
            continue  # drop old entry
        cleaned.append(e)

    # Append the current entry
    cleaned.append(entry)
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

# Pack-specific flavor
case "$ACTIVE_PACK" in
  terran)           echo -e "  ${DIM}\"Adjutant online. All systems nominal.\"${NC}" ;;
  protoss)          echo -e "  ${DIM}\"En taro Adun.\"${NC}" ;;
  zerg)             echo -e "  ${DIM}\"The Swarm grows stronger.\"${NC}" ;;
  cortana)          echo -e "  ${DIM}\"I've got it under control.\"${NC}" ;;
  guilty-spark)     echo -e "  ${DIM}\"Greetings. I am the Monitor of Installation 04.\"${NC}" ;;
  sergeant-johnson) echo -e "  ${DIM}\"Oorah! Let's move, people.\"${NC}" ;;
  gdi)              echo -e "  ${DIM}\"GDI forces deployed.\"${NC}" ;;
  nod)              echo -e "  ${DIM}\"By your command.\"${NC}" ;;
esac

echo ""
echo -e "  ${CYAN}Switch voices${NC} ${DIM}(any of: ${PACKS[*]})${NC}:"
echo "    ~/.claude/sounds/set-faction.sh cortana"
echo "    ~/.claude/sounds/set-faction.sh nod"
echo ""
echo -e "  ${CYAN}Test it:${NC}"
echo "    ~/.claude/sounds/play-random.sh ~/.claude/sounds/active/session-start"
echo ""
echo -e "  ${CYAN}Add custom sounds:${NC}"
echo "    Drop .mp3/.m4a files into ~/.claude/sounds/<pack>/<event>/"
echo ""
echo -e "  ${CYAN}Uninstall:${NC}"
echo "    ./uninstall.sh"
echo ""
echo -e "  ${DIM}Start a new Claude Code session to hear it.${NC}"
echo ""
