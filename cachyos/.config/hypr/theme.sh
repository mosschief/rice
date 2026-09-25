#!/bin/sh
# Rice day/night toggle (github.com/mosschief/rice theme-day.sh / theme-night.sh),
# adapted for Noctalia + kitty. Usage: theme.sh day|night
#
# Noctalia's "rice" palette (~/.config/noctalia/palettes/rice.json) themes the bar,
# kitty, GTK, Qt/KDE and btop; switching its mode re-renders those templates and
# reloads kitty. Hyprland reads the mode from the state file in config/theme.lua.
set -u

case "${1:-}" in
    day)   mode=light; wp=rice-day.png;   icons=Papirus-Rice ;;
    night) mode=dark;  wp=rice-night.png; icons=Papirus-Rice-Dark ;;
    *) echo "usage: $0 day|night" >&2; exit 1 ;;
esac

state="${XDG_STATE_HOME:-$HOME/.local/state}"
mkdir -p "$state"
echo "$1" > "$state/rice-theme"

# Compositor: borders + background colour
hyprctl reload >/dev/null

# Shell, bar, kitty, GTK/Qt via Noctalia
if [ "$(noctalia msg color-scheme-get 2>/dev/null)" != "custom rice" ]; then
    noctalia msg color-scheme-set custom rice
fi
noctalia msg theme-mode-set "$mode"
noctalia msg wallpaper-set "$HOME/.local/share/wallpapers/$wp"

# Icons (Papirus grey-folder overlay, built by ~/dotfiles/scripts/papirus-grey-folders.sh)
if [ -d "$HOME/.local/share/icons/$icons" ] || [ -d "/usr/share/icons/$icons" ]; then
    gsettings set org.gnome.desktop.interface icon-theme "$icons"
fi

# Firefox theme-switcher extension (~/dotfiles/.config/sway/theme-host.py watches this)
mkdir -p "$HOME/.config/sway"
echo "$mode" > "$HOME/.config/sway/current-theme"

# Claude Code theme
if [ -f "$HOME/.claude/settings.json" ]; then
    sed -i -E "s/\"theme\": \"(light|dark|auto)\"/\"theme\": \"$mode\"/" "$HOME/.claude/settings.json"
fi
