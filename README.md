# claude-notify

A Claude Code plugin that plays a sound and sends a desktop notification when:
- **Claude finishes a task** → "Task complete" sound + notification
- **Claude needs your input** (permission prompt, idle, MCP elicitation) → "Needs your input" sound + notification

Zero dependencies. Uses built-in OS sounds (`/System/Library/Sounds/` on macOS, `C:\Windows\Media\` on Windows).

## Install

### Recommended: copy into skills-dir

`~/.claude/skills/` is auto-loaded as `<name>@skills-dir` on next session — simplest local install, no marketplace, no JSON editing:

```bash
cp -R /path/to/claude-notify ~/.claude/skills/claude-notify
```

Restart Claude Code. Done.

### Manual (settings.json hook only)

```bash
cp hooks/notify.sh ~/.claude/hooks/notify.sh
chmod +x ~/.claude/hooks/notify.sh
```

Add to `~/.claude/settings.json`:

```json
{
  "hooks": {
    "Stop": [
      { "hooks": [{ "type": "command", "command": "~/.claude/hooks/notify.sh" }] }
    ],
    "Notification": [
      {
        "matcher": "permission_prompt|idle_prompt|agent_needs_input|elicitation_dialog",
        "hooks": [{ "type": "command", "command": "~/.claude/hooks/notify.sh" }]
      }
    ]
  }
}
```

Restart Claude Code.

### Other install paths (not recommended for local use)

| Path | Behavior |
|---|---|
| `~/.claude/plugins/<name>/` (symlink or copy) | **NOT auto-loaded** — Claude Code reads from `installed_plugins.json`, not directory scan. Use only with `claude plugin install` (requires marketplace) or `--plugin-dir` (session-only). |
| `--plugin-dir <path>` at CLI | Session-only override. Good for one-off testing. |
| Marketplace + `claude plugin install <name>` | For distribution to others. |

## Verify

```bash
# Task complete
echo '{"hook_event_name":"Stop"}' | ~/.claude/skills/claude-notify/hooks/notify.sh

# Needs input
echo '{"hook_event_name":"Notification","notification_type":"permission_prompt"}' | ~/.claude/skills/claude-notify/hooks/notify.sh
```

You should hear a chime and see a desktop notification.

## Troubleshooting

| Platform | Issue | Fix |
|---|---|---|
| macOS | No notification | System Settings → Notifications → grant Terminal/iTerm |
| macOS | `jq: command not found` | `brew install jq` |
| Windows | Toast blank on first run | Open PowerShell once interactively to initialize WinRT |
| Both | Hook never fires after install | See "Other install paths" above — most likely you used `~/.claude/plugins/` (doesn't auto-load) instead of `~/.claude/skills/` |
| Both | Plugin not in `/plugin list` | Run `claude plugin validate /path/to/claude-notify` to check structure |
| Both | Edits to source not taking effect | If you `cp`-installed, re-copy. If you want live edits, replace with symlink: `ln -sfn /path/to/source ~/.claude/skills/claude-notify` |

## For AI agents

**Trigger phrases** — invoke the `claude-notify` skill when the user says any of:
- "Set up Claude notifications" / "make Claude play a sound"
- "Alert me when Claude is done" / "notify me when Claude needs input"
- "I want a sound when Claude finishes"
- Or reports the plugin not working ("no sound", "no notification", "hook isn't firing")

**Workflow** (follow exactly):

1. **Detect state** — check if already installed:
   ```bash
   ls ~/.claude/skills/claude-notify/hooks/notify.sh 2>/dev/null
   ```
2. **Install** (if missing) — copy to skills-dir, NOT plugins-dir:
   ```bash
   cp -R /Users/FireTable/OpenClaw/Code/claude-notify ~/.claude/skills/claude-notify
   ```
   Then tell the user to restart Claude Code.
3. **Verify both scenarios** before reporting success — run both:
   ```bash
   echo '{"hook_event_name":"Stop"}' | ~/.claude/skills/claude-notify/hooks/notify.sh
   echo '{"hook_event_name":"Notification","notification_type":"permission_prompt"}' | ~/.claude/skills/claude-notify/hooks/notify.sh
   ```
4. **Troubleshoot** if user reports issues — see the table above + the `Critical install-path gotcha` section.
5. **Never install into `~/.claude/plugins/`** — that path is not auto-discovered.

**Customize sounds** — if user wants different sounds:
- macOS: edit the two `afplay` lines in `notify.sh` (15 built-ins in `/System/Library/Sounds/`)
- Windows: edit the two `SoundPlayer` lines (`C:\Windows\Media\*.wav`)
- Bump volume: change `afplay -v 2.0` to `3.0` on macOS

**Don't** — do not add new hooks for SubagentStop, TTS, webhooks, or multi-CLI support without explicit user request. Scope creep here is well-documented elsewhere (see `echook` and similar projects as cautionary tales).

## Files

```
claude-notify/
├── .claude-plugin/
│   └── plugin.json           # plugin metadata
├── hooks/
│   ├── hooks.json            # declares Stop + Notification hooks
│   └── notify.sh             # the script (the only code)
├── skills/
│   └── claude-notify/
│       └── SKILL.md          # AI-facing install + verify guide
└── README.md                 # this file
```

## Sounds used

| Scenario | macOS | Windows |
|---|---|---|
| Task complete | `Hero.aiff` (rising) | `tada.wav` (fanfare) |
| Needs input | `Ping.aiff` (soft) | `notify.wav` (default) |

Swap by editing `notify.sh` — 4 lines.

## License

MIT.