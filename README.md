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

**When to engage** — invoke the `claude-notify` skill if the user asks to "set up Claude notifications", "make Claude play a sound", "alert me when Claude is done", or reports the plugin isn't working.

**Full instructions live in the skill** — read `skills/claude-notify/SKILL.md` before doing anything. It has the workflow (detect → install → verify), the troubleshoot table, and a "do NOT" list.

**Quick reference** (so you know what you're getting into):

| Step | Command |
|---|---|
| Detect | `ls ~/.claude/skills/claude-notify/hooks/notify.sh` |
| Install | `cp -R /Users/FireTable/OpenClaw/Code/claude-notify ~/.claude/skills/claude-notify` |
| Verify Stop | `echo '{"hook_event_name":"Stop"}' \| ~/.claude/skills/claude-notify/hooks/notify.sh` |
| Verify Notification | `echo '{"hook_event_name":"Notification","notification_type":"permission_prompt"}' \| ~/.claude/skills/claude-notify/hooks/notify.sh` |

**Hard rule:** install into `~/.claude/skills/<name>/`, NEVER `~/.claude/plugins/<name>/`. The latter is not auto-discovered by Claude Code.

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