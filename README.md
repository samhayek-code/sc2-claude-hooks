# Claude Audio Hooks

Game voice-line sound packs for [Claude Code](https://docs.anthropic.com/en/docs/claude-code) event hooks. Plays a random line when a session starts, a task finishes, Claude asks for permission, or a command errors out — pulled from three franchises, switchable on a single symlink.

**StarCraft 2** · **Halo** · **Tiberian Sun** — 8 packs, ~330 cleaned clips.

> *"Battlecruiser operational."* — every time you start a session

## Install

One-liner (no clone needed):

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/samhayek-code/claude-audio-hooks/main/install.sh)
```

Or from the repo:

```bash
git clone https://github.com/samhayek-code/claude-audio-hooks.git
cd claude-audio-hooks
./install.sh
```

Every pack installs; the installer just asks which one to start with. Begin a new Claude Code session and you'll hear it. Switch any time with `set-faction.sh`.

## What It Does

Uses [Claude Code hooks](https://docs.anthropic.com/en/docs/claude-code/hooks) to trigger sounds on four events:

| Event | Hook | What plays |
|-------|------|------------|
| Session starts | `SessionStart` | Unit-ready / greeting lines |
| Task completes | `Stop` | Completion confirmations |
| Needs permission | `Notification` | Alert / awaiting-orders lines |
| Error occurs | `PostToolUseFailure` | Resource warnings / panic lines |

Error sounds are smart-filtered — they only fire on genuinely interesting failures (build errors, test failures, git conflicts, crashes, permission issues). Routine noise like `grep` no-match or `which` not-found is silenced, and a 15-second cooldown prevents rapid-fire.

The mechanism is pack-agnostic: every pack is a folder of four event buckets (`session-start`, `task-complete`, `needs-permission`, `error`), and `play-random.sh` picks a random clip from the active pack's bucket. The `active` symlink decides which pack plays.

## The Packs

| Pack | Franchise | Voices | Clips |
|------|-----------|--------|-------|
| `terran` | StarCraft 2 | Terran advisor + units | 28 |
| `protoss` | StarCraft 2 | Protoss advisor + units | 23 |
| `zerg` | StarCraft 2 | Zerg advisor + creature sounds | 24 |
| `cortana` | Halo | Cortana (Halo 2/3) | 80 |
| `guilty-spark` | Halo | 343 Guilty Spark (Halo 3) | 48 |
| `sergeant-johnson` | Halo | Sgt. Johnson | 47 |
| `gdi` | Tiberian Sun | EVA announcer + GDI units | 40 |
| `nod` | Tiberian Sun | CABAL + Nod units | 40 |

<details>
<summary><b>StarCraft 2 — full sound lists</b></summary>

### Terran (28)
Session start: Battlecruiser operational · Goliath online · Marine ready · Raven online · Siege tank ready
Task complete: Add-on complete · Ghost reporting · Job confirmed · Job's finished · Research complete · Salvage complete · Upgrade complete
Needs permission: Base under attack · Calldown launch · Forces under attack · Go ahead TacCom · Incoming orders · Nuclear strike · Nuke ready · Say the word · Standing by · What's your call?
Error: Build error · Construction interrupted · Need more gas · Need more supply · Not enough energy · Not enough minerals

### Protoss (23)
Session start: Carrier has arrived · Dark Templar ready · High Templar ready · I return to serve · Prismatic core online
Task complete: Merging is complete · Processed · Research complete · Upgrade complete · Warp-in complete
Needs permission: Awaiting command · Base under attack · Calldown launch · Command me · Fire at will Commander · Forces under attack · Input command · Standing by
Error: Build error · Construct additional pylons · Need more gas · Need more minerals · Not enough energy

### Zerg (24)
Mixes advisor announcements with organic creature sounds — hisses, screeches, and chittering from Banelings, Lurkers, Hydralisks, and Mutalisks.
Session start: Baneling spawned · Baneling ready · Lurker emerged · Egg hatched (×2)
Task complete: Evolution complete · Metamorphosis complete · Mutation complete · New queen · Baneling confirms · Lurker confirms
Needs permission: Base / Forces / Ally / Economy under attack · Calldown launch · Hydralisk awaits · Lurker awaits · Mutalisk awaits
Error: Build error · Need more gas · Need more minerals · Not enough energy · Spawn more Overlords
</details>

<details>
<summary><b>Halo</b></summary>

| Pack | Character |
|------|-----------|
| `cortana` | Cortana (Halo 2/3) |
| `guilty-spark` | 343 Guilty Spark (Halo 3) |
| `sergeant-johnson` | Sgt. Johnson |

Voice clips sourced from [101soundboards](https://www.101soundboards.com) and cleaned (see [How the audio was made](#how-the-audio-was-made)).
</details>

<details>
<summary><b>Tiberian Sun</b></summary>

| Pack | Voices | Sample |
|------|--------|--------|
| `gdi` | EVA announcer + GDI units | *"Construction complete." · "Ion cannon ready." · "Awaiting orders."* |
| `nod` | CABAL + Nod units | *"Your probability of success is insignificant and dropping." · "By your command."* |

Each pack blends its faction's announcer with its unit voices, the way the game layers them. `needs-permission` gets the units literally awaiting your command; `error` gets panic and menace. CABAL has no congratulatory line, so on `task-complete` he turns dark-ironic (*"Defeat of enemy predicted in T-minus 3, 2, 1."*) while his cyborgs report *"Executing."*
</details>

## Switch Voices

```bash
~/.claude/sounds/set-faction.sh protoss          # StarCraft 2
~/.claude/sounds/set-faction.sh cortana          # Halo
~/.claude/sounds/set-faction.sh nod              # Tiberian Sun
```

`set-faction.sh` auto-discovers any pack folder in `~/.claude/sounds/`, so all three franchises coexist; the `active` symlink selects which one plays. Run it with no argument to list what's installed.

## Add Custom Sounds

Drop any `.mp3` or `.m4a` into the matching event bucket:

```
~/.claude/sounds/terran/session-start/my-sound.mp3
~/.claude/sounds/cortana/error/another.mp3
```

The random picker includes them automatically. A whole new pack is just a folder with the four event buckets.

## How the Audio Was Made

The clips ship clean. Two pipelines live under [`tools/`](./tools), kept per-franchise.

**StarCraft 2 / Halo — soundboard cleaning** ([`tools/halo`](./tools/halo)). Raw 101soundboards rips carry two artifacts before each line: an in-game radio **ping** (5–6 fixed variants) and a spoken **"101soundboards" plug**.
- `fadefix.py` — trims leading dead air, adds a 10 ms fast-attack fade-in (kills the startup click).
- `cluster.py` — groups clip openings by cross-correlation to separate the recurring ping variants from real speech, so first words are never cut.
- `debeep.py` / `unified2.py` — strip the ping and the plug, then dedup lines that landed in two buckets.

Requires `numpy` + `ffmpeg`. Detection is acoustic, verified by ear.

**Tiberian Sun — extraction from freeware game data** ([`tools/tiberian-sun`](./tools/tiberian-sun), full writeup in its [README](./tools/tiberian-sun/README.md)). These are the original game clips, pulled on macOS without Windows tools (Tiberian Sun has been EA freeware since 2010).
- `extract_mix.py` — parses the Westwood "new format" MIX archive into raw `.AUD` files.
- `hashtest.py` — recovers canonical filenames by hashing each name against the embedded mix database; the `i`/`n` letter splits GDI from Nod.
- `ffmpeg` decodes Westwood ADPCM (`wsaud` / `adpcm_ima_ws`); [whisper.cpp](https://github.com/ggerganov/whisper.cpp) transcribes the corpus for bucket sorting.
- `build_pack.sh` + `*.manifest` — trim, loudness-normalize, click-guard, encode to mp3.

## Requirements

- **macOS** — uses `afplay` for playback
- **Claude Code** — with hooks support
- **python3** — for the installer's settings merge and error filtering (pre-installed on macOS)

**Linux:** swap `afplay` for `aplay`, `paplay`, or `mpv` in `sounds/play-random.sh`, then run `./install.sh --force`.

## Uninstall

```bash
./uninstall.sh
```

Removes the sounds, the hooks from `settings.json`, and the error cooldown cache. Your other Claude Code settings are preserved.

## Credits

- **StarCraft 2** — audio sourced from [StarCraft Wiki](https://starcraft.fandom.com/wiki/StarCraft_Wiki) and [nuclearlaunchdetected.com](http://nuclearlaunchdetected.com). StarCraft © Blizzard Entertainment.
- **Halo** — voice clips via [101soundboards](https://www.101soundboards.com). Halo, Cortana, 343 Guilty Spark, and Sgt. Johnson are trademarks of Microsoft / 343 Industries; franchise created by Bungie.
- **Tiberian Sun** — clips and franchise © Electronic Arts / Westwood Studios; game data via the [CnCNet](https://cncnet.org/tiberian-sun) community client (EA freeware); transcription by [whisper.cpp](https://github.com/ggerganov/whisper.cpp).
- Cover art is AI-generated fan art.

## License & Disclaimer

MIT — **the code and tooling, not the audio**. The voice clips are the property of their respective rights holders (Blizzard Entertainment; Microsoft / 343 Industries; Electronic Arts / Westwood Studios) and are included here for personal, non-commercial, fan use only. This project is unofficial and not affiliated with or endorsed by any of them. If you represent a rights holder and want clips removed, open an issue and they'll be taken down.
