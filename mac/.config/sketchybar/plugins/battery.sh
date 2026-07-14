#!/usr/bin/env bash
PCT=$(pmset -g batt | grep -Eo '[0-9]+%' | head -1)
sketchybar --set "$NAME" label="BAT ${PCT:-n/a}"
