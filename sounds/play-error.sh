#!/bin/bash
# Smart error sound wrapper — filters out noise from PostToolUseFailure.
# Reads hook JSON from stdin, then:
#   1. Skips user interrupts (not real errors)
#   2. Skips routine command failures (grep, which, pkill, etc.)
#   3. Only plays on genuinely interesting errors (build, test, git, crashes)
#   4. Enforces a cooldown so errors don't rapid-fire

SOUNDS_DIR="$HOME/.claude/sounds"
CACHE_DIR="$HOME/.cache"
mkdir -p "$CACHE_DIR"
COOLDOWN_FILE="$CACHE_DIR/sc2-claude-last-error"
COOLDOWN_SECONDS=15

# Read the hook JSON from stdin
INPUT=$(cat)

# Use python3 to decide whether this error is worth alerting on
SHOULD_PLAY=$(echo "$INPUT" | python3 -c "
import sys, json, re

try:
    d = json.load(sys.stdin)
except:
    print('no')
    sys.exit()

# Skip user interrupts
if d.get('is_interrupt'):
    print('no')
    sys.exit()

command = d.get('tool_input', {}).get('command', '')
error = d.get('error', '')
combined = command + ' ' + error

# --- Command denylist: these 'fail' as part of normal operation ---
skip_prefixes = [
    'which ', 'command -v ', 'type ',        # existence checks
    'grep ', 'rg ', 'ag ',                    # search (no match = exit 1)
    'pkill ', 'pgrep ',                       # no matching process
    'diff ', 'cmp ',                          # files differ = exit 1
    'find ', 'ls ', 'stat ',                  # file listing / checks
    'file ',                                  # file type checks
    'test ', '[ ',                            # conditional tests
    'cat ', 'head ', 'tail ',                 # reading files that may not exist
    'readlink ',                              # symlink checks
]

cmd_stripped = command.lstrip()
for prefix in skip_prefixes:
    if cmd_stripped.startswith(prefix):
        print('no')
        sys.exit()

# --- Error pattern allowlist: only play if something genuinely went wrong ---
interesting_patterns = [
    # Build / compile
    r'Build failed',
    r'ERROR in',
    r'error TS\d',                            # TypeScript
    r'SyntaxError',
    r'Module not found',
    r'Cannot find module',
    r'compilation failed',

    # Tests
    r'Tests?:.*failed',
    r'FAIL ',
    r'Assert(ion)?Error',
    r'test.*failed',
    r'✕|✗|FAILED',

    # Git
    r'fatal:',
    r'CONFLICT',
    r'rejected\b',
    r'merge conflict',
    r'not a git repository',

    # Permissions / system
    r'[Pp]ermission denied',
    r'EACCES',
    r'command not found',
    r'No space left',
    r'ENOSPC',
    r'Cannot allocate memory',
    r'ENOMEM',

    # Runtime crashes
    r'Segmentation fault',
    r'Killed',
    r'Traceback \(most recent',               # Python
    r'TypeError',
    r'ReferenceError',
    r'panic:',                                # Go / Rust
    r'SIGKILL|SIGSEGV|SIGABRT',
    r'core dumped',

    # Network
    r'ECONNREFUSED',
    r'Connection refused',
    r'ETIMEDOUT',

    # Package managers
    r'ERR!',                                  # npm
    r'error: could not install',
    r'Failed to resolve',
]

for pattern in interesting_patterns:
    if re.search(pattern, combined, re.IGNORECASE):
        print('yes')
        sys.exit()

# Default: skip — if no interesting pattern matched, stay silent
print('no')
" 2>/dev/null)

if [ "$SHOULD_PLAY" != "yes" ]; then
  exit 0
fi

# Cooldown: don't play if we played an error sound recently
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
