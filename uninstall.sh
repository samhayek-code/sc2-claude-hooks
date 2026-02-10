#!/bin/bash
# SC2 Claude Hooks — Uninstaller
# Removes sound files, hooks, and cache.

set -e

# ── Colors ──────────────────────────────────────────────────────────────────

CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
DIM='\033[2m'
BOLD='\033[1m'
NC='\033[0m'

print_step()    { echo -e "  ${CYAN}▶${NC} $1"; }
print_success() { echo -e "  ${GREEN}✓${NC} $1"; }
print_warning() { echo -e "  ${YELLOW}⚠${NC} $1"; }
print_error()   { echo -e "  ${RED}✗${NC} $1"; }

# ── Header ──────────────────────────────────────────────────────────────────

echo ""
echo -e "${CYAN}  ███████╗ ██████╗ ██████╗ ${NC}"
echo -e "${CYAN}  ██╔════╝██╔════╝ ╚════██╗${NC}"
echo -e "${CYAN}  ███████╗██║       █████╔╝${NC}"
echo -e "${CYAN}  ╚════██║██║      ██╔═══╝ ${NC}"
echo -e "${CYAN}  ███████║╚██████╗ ███████╗${NC}"
echo -e "${CYAN}  ╚══════╝ ╚═════╝ ╚══════╝${NC}"
echo -e "  ${DIM}Uninstaller${NC}"
echo ""

# ── Confirm ─────────────────────────────────────────────────────────────────

SOUNDS_DIR="$HOME/.claude/sounds"
SETTINGS_FILE="$HOME/.claude/settings.json"
CACHE_FILE="$HOME/.cache/sc2-claude-last-error"

if [ ! -d "$SOUNDS_DIR" ] && [ ! -f "$CACHE_FILE" ]; then
  print_warning "Nothing to uninstall — SC2 hooks not found"
  echo ""
  exit 0
fi

echo -e "  ${YELLOW}This will remove:${NC}"
[ -d "$SOUNDS_DIR" ] && echo "    ~/.claude/sounds/"
[ -f "$SETTINGS_FILE" ] && echo "    SC2 hooks from settings.json"
[ -f "$CACHE_FILE" ] && echo "    ~/.cache/sc2-claude-last-error"
echo ""

if [ -t 0 ]; then
  read -p "  Continue? [y/N]: " CONFIRM
else
  CONFIRM=$(bash -c 'read -p "  Continue? [y/N]: " c < /dev/tty && echo "$c"' 2>/dev/null) || CONFIRM="y"
fi

if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
  echo ""
  echo -e "  ${DIM}Aborted.${NC}"
  echo ""
  exit 0
fi

echo ""

# ── Remove hooks from settings.json ────────────────────────────────────────

if [ -f "$SETTINGS_FILE" ] && command -v python3 &>/dev/null; then
  print_step "Removing hooks from settings.json..."

  cp "$SETTINGS_FILE" "$SETTINGS_FILE.backup"

  python3 << 'PYEOF'
import json, os

settings_path = os.path.expanduser("~/.claude/settings.json")

with open(settings_path, "r") as f:
    settings = json.load(f)

SC2_MARKER = ".claude/sounds/"
hooks = settings.get("hooks", {})
events_to_delete = []

for event, entries in hooks.items():
    cleaned = []
    for entry in entries:
        cmds = [h.get("command", "") for h in entry.get("hooks", [])]
        if any(SC2_MARKER in cmd for cmd in cmds):
            continue  # remove SC2 entry
        cleaned.append(entry)

    if cleaned:
        hooks[event] = cleaned
    else:
        events_to_delete.append(event)

for event in events_to_delete:
    del hooks[event]

# Remove empty hooks key entirely
if not hooks:
    settings.pop("hooks", None)
else:
    settings["hooks"] = hooks

with open(settings_path, "w") as f:
    json.dump(settings, f, indent=2)
    f.write("\n")
PYEOF

  print_success "Hooks removed from settings.json"
  print_success "Backed up to settings.json.backup"
else
  if [ ! -f "$SETTINGS_FILE" ]; then
    print_success "No settings.json to clean"
  else
    print_warning "python3 not found — manually remove SC2 hooks from settings.json"
  fi
fi

# ── Remove sounds directory ────────────────────────────────────────────────

if [ -d "$SOUNDS_DIR" ]; then
  print_step "Removing sounds..."
  rm -rf "$SOUNDS_DIR"
  print_success "Removed ~/.claude/sounds/"
else
  print_success "No sounds directory to remove"
fi

# ── Remove cache file ──────────────────────────────────────────────────────

if [ -f "$CACHE_FILE" ]; then
  rm -f "$CACHE_FILE"
  print_success "Removed error cooldown cache"
fi

# ── Done ───────────────────────────────────────────────────────────────────

echo ""
echo -e "  ${GREEN}╔═════════════════════════════════════════════╗${NC}"
echo -e "  ${GREEN}║${NC}          ${BOLD}UNINSTALL COMPLETE${NC}                ${GREEN}║${NC}"
echo -e "  ${GREEN}╚═════════════════════════════════════════════╝${NC}"
echo -e "  ${DIM}\"Nuclear launch cancelled.\"${NC}"
echo ""
echo -e "  ${DIM}Reinstall anytime:${NC}"
echo "    bash <(curl -fsSL https://raw.githubusercontent.com/samhayek-code/sc2-claude-hooks/main/install.sh)"
echo ""
