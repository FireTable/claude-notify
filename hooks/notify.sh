#!/usr/bin/env bash
# notify.sh — Claude Code hook: play sound + send OS notification
#
# Triggered by: Stop (task complete) and Notification (needs human input)
# Reads hook JSON from stdin. Optional $1 override: "task_complete" | "needs_input"
# Platforms: macOS (afplay + osascript), Windows (SoundPlayer + WinRT Toast)

set -uo pipefail

INPUT=$(cat)
EVENT=$(printf '%s' "$INPUT" | jq -r '.hook_event_name // ""' 2>/dev/null)

# Map event → scenario
SCENARIO=""
case "$EVENT" in
    Stop)              SCENARIO="task_complete" ;;
    Notification)      SCENARIO="needs_input" ;;  # ponytail: all notification types treated the same; split later if needed
esac

# Manual override for testing: ./notify.sh task_complete
[[ -n "${1:-}" ]] && SCENARIO="$1"

if [[ -z "$SCENARIO" ]]; then
    exit 0
fi

UNAME=$(uname -s)

notify_macos() {
    local sound="$1" title="$2" msg="$3"
    afplay -v 2.0 "$sound" &>/dev/null &  # ponytail: 2x volume; bump to 3.0 if still quiet
    osascript -e "display notification \"$msg\" with title \"$title\"" &>/dev/null &
}

notify_windows() {
    local sound="$1" title="$2" msg="$3"
    # Background via bash &; PowerShell startup ~500ms but hook returns immediately
    powershell.exe -ExecutionPolicy Bypass -NoProfile -Command "
        (New-Object Media.SoundPlayer '$sound').Play();
        [Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime] | Out-Null;
        [Windows.Data.Xml.Dom.XmlDocument, Windows.Data.Xml.Dom.XmlDocument, ContentType = WindowsRuntime] | Out-Null;
        \$xml = New-Object Windows.Data.Xml.Dom.XmlDocument;
        \$xml.LoadXml('<toast duration=\"short\"><visual><binding template=\"ToastGeneric\"><text>$title</text><text>$msg</text></binding></visual></toast>');
        \$toast = [Windows.UI.Notifications.ToastNotification]::new(\$xml);
        [Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier('Claude Code').Show(\$toast);
    " &>/dev/null &
}

case "$UNAME" in
    Darwin)
        if [[ "$SCENARIO" == "task_complete" ]]; then
            notify_macos "/System/Library/Sounds/Hero.aiff" "Claude Code" "Task complete"
        else
            notify_macos "/System/Library/Sounds/Ping.aiff" "Claude Code" "Needs your input"
        fi
        ;;
    MINGW*|CYGWIN*|MSYS*)
        if [[ "$SCENARIO" == "task_complete" ]]; then
            notify_windows 'C:\Windows\Media\tada.wav' "Claude Code" "Task complete"
        else
            notify_windows 'C:\Windows\Media\notify.wav' "Claude Code" "Needs your input"
        fi
        ;;
    *)
        # Linux/other: out of scope (no built-in notify on minimal systems)
        exit 0
        ;;
esac

exit 0