# SC2 Claude Hooks

StarCraft 2 sound effects for [Claude Code](https://docs.anthropic.com/en/docs/claude-code). Plays random SC2 voice lines when things happen in your terminal — session starts, tasks complete, permission prompts, and errors.

Choose your faction: **Terran**, **Protoss**, or **Zerg**.

> *"Battlecruiser operational."* — every time you start a session

## Install

One-liner (no clone needed):

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/samhayek-code/sc2-claude-hooks/main/install.sh)
```

Or from the repo:

```bash
git clone https://github.com/samhayek-code/sc2-claude-hooks.git
cd sc2-claude-hooks
./install.sh
```

The installer will ask you to pick a faction. Start a new Claude Code session and you'll hear it.

## What It Does

Uses [Claude Code hooks](https://docs.anthropic.com/en/docs/claude-code/hooks) to trigger sound effects on four events:

| Event | Hook | What plays |
|-------|------|------------|
| Session starts | `SessionStart` | Unit ready lines ("Goliath online", "Carrier has arrived") |
| Task completes | `Stop` | Completion confirmations ("Job's finished", "Evolution complete") |
| Needs permission | `Notification` | Alert/request lines ("Nuclear launch detected", "Awaiting command") |
| Error occurs | `PostToolUseFailure` | Resource warnings ("Not enough minerals", "Spawn more Overlords") |

Error sounds are smart-filtered — they only fire on genuinely interesting failures (build errors, test failures, git conflicts, crashes, permission issues). Routine noise like `grep` no-match or `which` not-found is silenced. A 15-second cooldown prevents rapid-fire.

## Manual Install

If you prefer not to run the installer:

1. Copy the `sounds/` directory to `~/.claude/sounds/`
2. Make scripts executable: `chmod +x ~/.claude/sounds/play-random.sh ~/.claude/sounds/play-error.sh ~/.claude/sounds/set-faction.sh`
3. Create the faction symlink: `ln -s ~/.claude/sounds/terran ~/.claude/sounds/active`
4. Copy the hooks from `hooks.json` into your `~/.claude/settings.json` under the `"hooks"` key

## Switch Factions

```bash
~/.claude/sounds/set-faction.sh terran
~/.claude/sounds/set-faction.sh protoss
~/.claude/sounds/set-faction.sh zerg
```

## Sound List

### Terran (28 sounds)

| Event | Sound | File |
|-------|-------|------|
| **Session Start** | Battlecruiser operational | `battlecruiser-operational.mp3` |
| | Goliath online | `goliath-online.m4a` |
| | Marine ready | `marine-ready.mp3` |
| | Raven online | `raven-online.mp3` |
| | Siege tank ready | `siege-tank-ready.mp3` |
| **Task Complete** | Add-on complete | `addon-complete.mp3` |
| | Ghost reporting | `ghost-reporting.m4a` |
| | Job confirmed | `job-confirmed.m4a` |
| | Job's finished | `jobs-finished.mp3` |
| | Research complete | `research-complete.mp3` |
| | Salvage complete | `salvage-complete.mp3` |
| | Upgrade complete | `upgrade-complete.mp3` |
| **Needs Permission** | Base under attack | `base-under-attack.mp3` |
| | Calldown launch | `calldown-launch.mp3` |
| | Forces under attack | `forces-under-attack.mp3` |
| | Go ahead, TacCom | `go-ahead-taccom.m4a` |
| | Incoming orders | `incoming-orders.m4a` |
| | Nuclear strike | `nuclear-strike.mp3` |
| | Nuke ready | `nuke-ready.mp3` |
| | Say the word | `say-the-word.m4a` |
| | Standing by | `standing-by.m4a` |
| | What's your call? | `whats-your-call.m4a` |
| **Error** | Build error | `build-error.mp3` |
| | Construction interrupted | `construction-interrupted.mp3` |
| | Need more gas | `need-more-gas.mp3` |
| | Need more supply | `need-more-supply.mp3` |
| | Not enough energy | `not-enough-energy.mp3` |
| | Not enough minerals | `not-enough-minerals.mp3` |

### Protoss (23 sounds)

| Event | Sound | File |
|-------|-------|------|
| **Session Start** | Carrier has arrived | `carrier-has-arrived.mp3` |
| | Dark Templar ready | `dark-templar-ready.mp3` |
| | High Templar ready | `high-templar-ready.mp3` |
| | I return to serve | `i-return-to-serve.mp3` |
| | Prismatic core online | `prismatic-core-online.mp3` |
| **Task Complete** | Merging is complete | `merging-is-complete.m4a` |
| | Processed | `processed.m4a` |
| | Research complete | `research-complete.mp3` |
| | Upgrade complete | `upgrade-complete.mp3` |
| | Warp-in complete | `warp-in-complete.mp3` |
| **Needs Permission** | Awaiting command | `awaiting-command.m4a` |
| | Base under attack | `base-under-attack.mp3` |
| | Calldown launch | `calldown-launch.mp3` |
| | Command me | `command-me.m4a` |
| | Fire at will, Commander | `fire-at-will-commander.m4a` |
| | Forces under attack | `forces-under-attack.mp3` |
| | Input command | `input-command.m4a` |
| | Standing by | `standing-by.m4a` |
| **Error** | Build error | `build-error.mp3` |
| | Construct additional pylons | `construct-additional-pylons.mp3` |
| | Need more gas | `need-more-gas.mp3` |
| | Need more minerals | `need-more-minerals.mp3` |
| | Not enough energy | `not-enough-energy.mp3` |

### Zerg (24 sounds)

Zerg mixes advisor announcements with organic creature sounds — hisses, screeches, and chittering from Banelings, Lurkers, Hydralisks, and Mutalisks.

| Event | Sound | File |
|-------|-------|------|
| **Session Start** | Baneling spawned | `baneling-spawned.mp3` |
| | Baneling ready | `baneling-ready.mp3` |
| | Lurker emerged | `lurker-emerged.mp3` |
| | Egg hatched | `egg-hatched.mp3` |
| | Egg hatched (variant) | `egg-hatched-2.mp3` |
| **Task Complete** | Evolution complete | `evolution-complete.mp3` |
| | Metamorphosis complete | `metamorphosis-complete.mp3` |
| | Mutation complete | `mutation-complete.mp3` |
| | New queen | `new-queen.mp3` |
| | Baneling confirms | `baneling-confirms.mp3` |
| | Lurker confirms | `lurker-confirms.mp3` |
| **Needs Permission** | Base under attack | `base-under-attack.mp3` |
| | Forces under attack | `forces-under-attack.mp3` |
| | Ally under attack | `ally-under-attack.mp3` |
| | Economy under attack | `economy-under-attack.mp3` |
| | Calldown launch | `calldown-launch.mp3` |
| | Hydralisk awaits | `hydralisk-awaits.mp3` |
| | Lurker awaits | `lurker-awaits.mp3` |
| | Mutalisk awaits | `mutalisk-awaits.mp3` |
| **Error** | Build error | `build-error.mp3` |
| | Need more gas | `need-more-gas.mp3` |
| | Need more minerals | `need-more-minerals.mp3` |
| | Not enough energy | `not-enough-energy.mp3` |
| | Spawn more Overlords | `spawn-more-overlords.mp3` |

## Add Custom Sounds

Drop any `.mp3` or `.m4a` file into the appropriate folder:

```
~/.claude/sounds/terran/session-start/my-custom-sound.mp3
~/.claude/sounds/zerg/error/another-sound.mp3
```

The random picker will include them automatically.

## Requirements

- **macOS** — uses `afplay` for audio playback
- **Claude Code** — with hooks support
- **python3** — for the installer's settings merge and error filtering (pre-installed on macOS)

**Linux:** Swap `afplay` for `aplay`, `paplay`, or `mpv` in `sounds/play-random.sh`, then run `./install.sh --force`.

## Uninstall

```bash
./uninstall.sh
```

Removes sounds, hooks from `settings.json`, and the error cooldown cache. Your other Claude Code settings are preserved.

## Credits

- Sound effects sourced from [StarCraft Wiki](https://starcraft.fandom.com/wiki/StarCraft_Wiki) and [nuclearlaunchdetected.com](http://nuclearlaunchdetected.com)
- StarCraft is a trademark of Blizzard Entertainment


## License

MIT — the code, not the sounds. StarCraft audio is property of Blizzard Entertainment and included here for personal, non-commercial use under fair use.

