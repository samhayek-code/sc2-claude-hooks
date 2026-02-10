# SC2 Claude Hooks

StarCraft 2 sound effects for [Claude Code](https://docs.anthropic.com/en/docs/claude-code). Plays random SC2 voice lines when things happen in your terminal — session starts, tasks complete, permission prompts, and errors.

Choose your faction: **Terran** or **Protoss**.

> *"Battlecruiser operational."* — every time you start a session

## Quick Install

```bash
git clone https://github.com/samhayek-code/sc2-claude-hooks.git
cd sc2-claude-hooks
./install.sh
```

That's it. Start a new Claude Code session and you'll hear it.

## What It Does

Uses [Claude Code hooks](https://docs.anthropic.com/en/docs/claude-code/hooks) to trigger sound effects on four events:

| Event | Hook | What plays |
|-------|------|------------|
| Session starts | `SessionStart` | Unit ready lines ("Goliath online", "Carrier has arrived") |
| Task completes | `Stop` | Completion confirmations ("Job's finished", "Upgrade complete") |
| Needs permission | `Notification` | Alert/request lines ("Nuclear launch detected", "Awaiting command") |
| Error occurs | `PostToolUseFailure` | Resource warnings ("Not enough minerals", "Construct additional pylons") |

## Manual Install

If you prefer not to run the installer:

1. Copy the `sounds/` directory to `~/.claude/sounds/`
2. Make scripts executable: `chmod +x ~/.claude/sounds/play-random.sh ~/.claude/sounds/set-faction.sh`
3. Create the faction symlink: `ln -s ~/.claude/sounds/terran ~/.claude/sounds/active`
4. Copy the hooks from `hooks.json` into your `~/.claude/settings.json` under the `"hooks"` key

## Switch Factions

```bash
~/.claude/sounds/set-faction.sh protoss
~/.claude/sounds/set-faction.sh terran
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

## Add Custom Sounds

Drop any `.mp3` or `.m4a` file into the appropriate folder:

```
~/.claude/sounds/terran/session-start/my-custom-sound.mp3
~/.claude/sounds/protoss/error/another-sound.m4a
```

The random picker will include them automatically.

## Requirements

- **macOS** — uses `afplay` for audio playback
- **Claude Code** — with hooks support
- **python3** — for the installer's settings merge (pre-installed on macOS)

Linux users: swap `afplay` for `aplay`, `paplay`, or `mpv` in `play-random.sh`.

## Credits

- Sound effects sourced from [StarCraft Wiki](https://starcraft.fandom.com/wiki/StarCraft_Wiki) and [nuclearlaunchdetected.com](http://nuclearlaunchdetected.com)
- StarCraft is a trademark of Blizzard Entertainment
- Inspired by [Delba's tweet](https://x.com/delaboratory/status/1929237508283879556) about Claude Code sound hooks

## License

MIT — the code, not the sounds. StarCraft audio is property of Blizzard Entertainment and included here for personal, non-commercial use under fair use.
