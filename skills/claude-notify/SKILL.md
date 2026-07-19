---
name: claude-notify
description: Install and troubleshoot the claude-notify plugin (sound + OS notification when Claude Code finishes or needs input). Use when the user asks to "set up notifications", "make Claude play a sound", "alert me when Claude is done", or asks why the plugin isn't working.
---

# claude-notify

Plays a sound + sends a desktop notification when:
- **Claude finishes a task** (Stop hook) → "Task complete" + rising chime
- **Claude needs human input** (Notification hook: permission prompts, idle prompts, elicitation dialogs) → "Needs your input" + soft ping

Supported: macOS (afplay + osascript), Windows (SoundPlayer + WinRT Toast). No dependencies.

## Install

**Recommended — copy into skills-dir (auto-loads as `<name>@skills-dir` next session):**

```bash
cp -R /path/to/claude-notify ~/.claude/skills/claude-notify
```

Then restart Claude Code. No marketplace, no JSON editing, no reload command needed.

**Manual (settings.json hook only, no plugin discovery):**

1. Copy the script: `cp hooks/notify.sh ~/.claude/hooks/notify.sh && chmod +x ~/.claude/hooks/notify.sh`
2. Add to `~/.claude/settings.json`:
   ```json
   {
     "hooks": {
       "Stop": [{ "hooks": [{ "type": "command", "command": "~/.claude/hooks/notify.sh" }] }],
       "Notification": [
         {
           "matcher": "permission_prompt|idle_prompt|agent_needs_input|elicitation_dialog",
           "hooks": [{ "type": "command", "command": "~/.claude/hooks/notify.sh" }]
         }
       ]
     }
   }
   ```
3. Restart Claude Code.

## Critical install-path gotcha

**Do NOT install into `~/.claude/plugins/<name>/` for local dev** — Claude Code does NOT auto-discover plugins from that directory. It reads from `installed_plugins.json`, which is only populated by:
- `claude plugin install <name>` (requires marketplace entry)
- `--plugin-dir <path>` CLI flag (session-only)

Symlinking into `~/.claude/plugins/` will pass `claude plugin validate` and the file is there, but hooks won't fire. Use `~/.claude/skills/<name>/` instead — that path IS auto-loaded.

## Verify

After installing, **always verify both scenarios** before declaring success:

```bash
# Test "task complete" — should play Hero.aiff + notification "Task complete"
echo '{"hook_event_name":"Stop"}' | ~/.claude/skills/claude-notify/hooks/notify.sh

# Test "needs input" — should play Ping.aiff + notification "Needs your input"
echo '{"hook_event_name":"Notification","notification_type":"permission_prompt"}' | ~/.claude/skills/claude-notify/hooks/notify.sh
```

On macOS, if no sound plays: check `System Settings → Notifications → Terminal` (or iTerm2) is allowed to show notifications. The terminal app is the *sender* of the osascript notification.

On Windows, if toast doesn't show: first run unlocks WinRT — execute once interactively in PowerShell to accept the prompt, then hooks work normally.

## Troubleshoot

| Symptom | Likely cause | Fix |
|---|---|---|
| Hook never fires after install | Plugin in `~/.claude/plugins/` (doesn't auto-load) | Move to `~/.claude/skills/<name>/` and restart Claude Code |
| Hook never fires after manual install | Wrong path in settings.json | Use absolute path (`~/.claude/skills/...` or `/Users/...`) |
| Plugin not in `/plugin list` | Installed as skills-dir plugin (intentional, not a marketplace plugin) | `/plugin list` shows marketplace plugins only — that's expected |
| No sound, no notification | `jq` missing | `brew install jq` (mac) or use WSL/Git Bash on Windows |
| macOS notification silent | Terminal not granted permission | System Settings → Notifications → grant to Terminal/iTerm |
| Windows toast blank/missing | WinRT not initialized | Run `powershell.exe -Command "[Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime]"` once |
| Hook fires but slow on Windows | PowerShell startup (~500ms) | Acceptable trade-off; toast needs WinRT, can't avoid |
| Edits to source repo not taking effect | `cp`-installed; skills-dir is a copy, not a symlink | Re-`cp` after edits, or `rm -rf ~/.claude/skills/claude-notify && ln -sfn /path/to/source ~/.claude/skills/claude-notify` |
| Want different sounds | macOS has 15 built-ins in `/System/Library/Sounds/`; Windows has ~10 in `C:\Windows\Media\` | Edit the two `afplay` / `SoundPlayer` lines in `notify.sh` |
| Validate plugin structure | `claude plugin validate /path/to/claude-notify` | Returns OK if `.claude-plugin/plugin.json` is valid JSON and required fields present |

## Customizing

Edit `hooks/notify.sh` directly. The script is ~50 lines, no abstractions. Two sound files to swap, two notification strings to change. After editing, re-`cp` (or switch to symlink).

## Unused events (intentional)

We don't register `SubagentStop` (too noisy — fires for every subagent), `PermissionRequest` (covered by `Notification` matcher `permission_prompt`), or `StopFailure` (rare, no clear sound fits). Add them yourself if you want them.