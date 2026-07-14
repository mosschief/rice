#!/usr/bin/env sh
# Rice palette — from github.com/mosschief/rice (williamjansson.com colors).
# Reads the current theme (~/.config/rice/current-theme = "day" | "night")
# and exports colors for borders, sketchybar, and the launcher.
#
#   day  : bg #f2f1e5  accent #deddd1  fg #000000
#   night: bg #1c1b16  accent #2e2d26  fg #f2f1e5

RICE_DIR="${HOME}/.config/rice"
RICE_THEME="$(cat "${RICE_DIR}/current-theme" 2>/dev/null || echo day)"

if [ "$RICE_THEME" = "night" ]; then
    RICE_BG="1c1b16"; RICE_ACCENT="2e2d26"; RICE_FG="f2f1e5"
else
    RICE_THEME="day"
    RICE_BG="f2f1e5"; RICE_ACCENT="deddd1"; RICE_FG="000000"
fi

# bare hex (RRGGBB) — used by `choose`
export RICE_THEME RICE_BG RICE_ACCENT RICE_FG
# 0xAARRGGBB (opaque) — used by borders + sketchybar
export RICE_BG_ARGB="0xff${RICE_BG}"
export RICE_ACCENT_ARGB="0xff${RICE_ACCENT}"
export RICE_FG_ARGB="0xff${RICE_FG}"
