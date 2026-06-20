#!/bin/bash
# Build a sound pack from a manifest of extracted TibSun EVA/CABAL clips.
# Usage: TIBSUN_SRC=/path/to/named build_pack.sh <manifest> <pack-name> [dest-dir]
#   <manifest>   lines of  canon|event|output-name  (see gdi.manifest / nod.manifest)
#   <pack-name>  e.g. gdi
#   [dest-dir]   default: ~/.claude/sounds
# Reads $TIBSUN_SRC/<canon>.wav (canonical WAVs from extract_mix.py + ffmpeg),
# trims silence, normalizes loudness, adds click-guard fades, encodes mp3.
set -e
MANIFEST="$1"; PACK="$2"
SRC="${TIBSUN_SRC:-$HOME/tibsun-spike/named}"
DEST="${3:-$HOME/.claude/sounds}/$PACK"
FILTER="silenceremove=start_periods=1:start_threshold=-50dB:start_silence=0.03,areverse,\
silenceremove=start_periods=1:start_threshold=-50dB:start_silence=0.03,\
afade=t=in:st=0:d=0.012,areverse,afade=t=in:st=0:d=0.012,\
loudnorm=I=-16:TP=-1.5:LRA=11"

n=0
while IFS='|' read -r canon event out; do
  [[ "$canon" =~ ^#.*$ || -z "$canon" ]] && continue
  canon="${canon// /}"; event="${event// /}"; out="${out// /}"
  mkdir -p "$DEST/$event"
  ffmpeg -hide_banner -loglevel error -fflags +discardcorrupt -y \
    -i "$SRC/$canon.wav" -af "$FILTER" \
    -ar 44100 -ac 1 -c:a libmp3lame -q:a 4 "$DEST/$event/$out.mp3" 2>/dev/null
  dur=$(ffprobe -v error -show_entries format=duration -of default=nk=1:nw=1 "$DEST/$event/$out.mp3" 2>/dev/null)
  printf "  %-16s %-22s %5.2fs\n" "$event" "$out.mp3" "$dur"
  n=$((n+1))
done < "$MANIFEST"
echo "built $n clips into $DEST"
