#!/bin/bash
# Picks a random sound from the given directory and plays it async.
# Usage: play-random.sh <directory>
# Supports .mp3 and .m4a files.

# Playback volume multiplier for afplay (1.0 = full, 0.5 = half).
VOLUME="${SC2_VOLUME:-0.5}"

dir="$1"
if [ -z "$dir" ] || [ ! -d "$dir" ]; then
  exit 0
fi

# Collect all playable audio files
files=()
for f in "$dir"/*.mp3 "$dir"/*.m4a; do
  [ -f "$f" ] && files+=("$f")
done

# Nothing to play
if [ ${#files[@]} -eq 0 ]; then
  exit 0
fi

# Kill any currently playing sound so they don't overlap
pkill -x afplay 2>/dev/null

# Pick a random file and play it in the background
afplay -v "$VOLUME" "${files[RANDOM % ${#files[@]}]}" &
