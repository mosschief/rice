#!/bin/sh
# Single entry point for locking (keybinds, lid switch).
# Uses the Noctalia lock screen. Noctalia also locks itself before sleep via a
# logind inhibitor, so a second lock client (hyprlock) must not be used here:
# two clients racing for ext-session-lock left the bar frozen after unlock.
#
#   lock.sh         lock
#   lock.sh --now   same; kept so existing callers (lid switch) keep working
set -eu

noctalia msg session lock
# Give Noctalia a moment to take the session lock so suspend can't win the
# race and flash the desktop on resume.
sleep 0.3
