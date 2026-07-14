#!/usr/bin/env bash
if [ "$SENDER" = "volume_change" ]; then
    sketchybar --set "$NAME" label="VOL ${INFO}%"
else
    VOL=$(osascript -e 'output volume of (get volume settings)' 2>/dev/null)
    sketchybar --set "$NAME" label="VOL ${VOL:-?}%"
fi
