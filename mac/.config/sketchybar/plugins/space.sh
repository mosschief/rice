#!/usr/bin/env bash
# Current mission-control Space index for the focused display (via yabai query).
SPACE=$(/opt/homebrew/bin/yabai -m query --spaces --space 2>/dev/null \
        | grep -o '"index":[0-9]*' | head -1 | cut -d: -f2)
[ -z "$SPACE" ] && SPACE="?"
sketchybar --set "$NAME" label="$SPACE"
