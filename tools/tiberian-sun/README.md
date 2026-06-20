# tools — extraction & build pipeline

How the packs were made: original Tiberian Sun game audio, extracted on macOS with no Windows
tools. Reproducible from freeware game data.

## Flow

```
Speech01/02.mix ──extract_mix.py──▶ *.aud ──ffmpeg(wsaud)──▶ *.wav
       │                                                        │
   hashtest.py ──▶ canonical names (00-iNNN.aud)          whisper.cpp
       │                                                        │
       └──────────────▶ named/<canon>.wav ◀────────────────────┘
                              │
                    build_pack.sh + *.manifest ──▶ ~/.claude/sounds/<pack>/
```

## Scripts

- **`extract_mix.py <mix> <outdir>`** — parses a Westwood "new format" MIX (unencrypted:
  `u32` flags, `u16` count, `u32` body size, then a `{id, offset, size}` index) and writes each
  entry as a raw `.AUD`. One entry is the XCC Local Mix Database (filename table), not audio.
- **`hashtest.py <mix>...`** — recovers canonical filenames. CRC32 of the uppercased name,
  padded with a `(len & 3)` count byte + repeated first char of the last block when not 4-byte
  aligned, maps each LMD name to an index id (100% match). The `i`/`n` letter splits GDI / Nod.
- **`build_pack.sh <manifest> <pack>`** — trim silence → loudnorm → click-guard fades → mp3.
  Source WAVs via `TIBSUN_SRC` (default `~/tibsun-spike/named`).
- **`gdi.manifest` / `nod.manifest`** — `canon|event|output-name` per line.

## Source & deps

- Game data: [CnCNet TS client package](https://github.com/CnCNet/cncnet-ts-client-package)
  ships `MIX/Speech01.mix` + `Speech02.mix` as loose files (Tiberian Sun is EA freeware).
- `ffmpeg` (Westwood `wsaud` / `adpcm_ima_ws` are built in), `python3`, and `whisper-cpp`
  for transcription/labeling.

## Reproduce

```bash
mkdir -p ~/tibsun-spike/{mix,aud,wav,named} && cd ~/tibsun-spike
base=https://raw.githubusercontent.com/CnCNet/cncnet-ts-client-package/master/MIX
curl -sL "$base/Speech01.mix" -o mix/Speech01.mix
curl -sL "$base/Speech02.mix" -o mix/Speech02.mix
python3 tools/extract_mix.py mix/Speech01.mix aud/s1     # + s2
# ffmpeg each aud -> named/<canon>.wav (see hashtest.py for id->name), then:
TIBSUN_SRC=~/tibsun-spike/named tools/build_pack.sh tools/gdi.manifest gdi
```
