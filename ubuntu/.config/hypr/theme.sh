#!/bin/sh
# Rice day/night toggle, Ubuntu variant: cachyos/.config/hypr/theme.sh adapted
# for Hyprland 0.52 (hyprland.conf, no Lua) and foot. Usage: theme.sh day|night
#
# Noctalia's "rice" palette (~/.config/noctalia/palettes/rice.json) themes the
# bar, foot, GTK 3/4 and btop; switching its mode re-renders those templates.
# Hyprland takes its colours from ~/.local/state/rice-theme.conf, which is
# written here and sourced at the end of hyprland.conf so a reload keeps them.
set -u

case "${1:-}" in
    day)
        mode=light; wp=rice-day.png; icons=Papirus-Rice; scheme=default
        bg=f2f1e5; active=000000; inactive=deddd1 ;;
    night)
        mode=dark; wp=rice-night.png; icons=Papirus-Rice-Dark; scheme=prefer-dark
        bg=1c1b16; active=f2f1e5; inactive=2e2d26 ;;
    *) echo "usage: $0 day|night" >&2; exit 1 ;;
esac

state="${XDG_STATE_HOME:-$HOME/.local/state}"
mkdir -p "$state"
echo "$1" > "$state/rice-theme"
cat > "$state/rice-theme.conf" <<EOF
# Written by ~/.config/hypr/theme.sh ($1) - do not edit.
general {
    col.active_border   = rgb($active)
    col.inactive_border = rgb($inactive)
}
group {
    col.border_active          = rgb($active)
    col.border_inactive        = rgb($inactive)
    col.border_locked_active   = rgb($active)
    col.border_locked_inactive = rgb($inactive)
    groupbar {
        col.active          = rgb($active)
        col.inactive        = rgb($inactive)
        col.locked_active   = rgb($active)
        col.locked_inactive = rgb($inactive)
    }
}
misc {
    background_color = rgb($bg)
}
EOF

# Compositor: borders + background colour (outside a session there is nothing
# to reload; the file above is picked up at the next start)
if [ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]; then
    hyprctl reload >/dev/null
fi

# Shell, bar, foot, GTK via Noctalia
if pgrep -x noctalia >/dev/null; then
    if [ "$(noctalia msg color-scheme-get 2>/dev/null)" != "custom rice" ]; then
        noctalia msg color-scheme-set custom rice
    fi
    noctalia msg theme-mode-set "$mode"
    noctalia msg wallpaper-set "$HOME/.local/share/wallpapers/$wp"
fi

# System colour scheme (Firefox, Electron, libadwaita follow it)
gsettings set org.gnome.desktop.interface color-scheme "$scheme"

# Icons (Papirus grey-folder overlay, built by scripts/papirus-grey-folders.sh)
if [ -d "$HOME/.local/share/icons/$icons" ] || [ -d "/usr/share/icons/$icons" ]; then
    gsettings set org.gnome.desktop.interface icon-theme "$icons"
fi

# Firefox theme-switcher extension (.config/sway/theme-host.py watches this)
mkdir -p "$HOME/.config/sway"
echo "$mode" > "$HOME/.config/sway/current-theme"

# Claude Code theme
if [ -f "$HOME/.claude/settings.json" ]; then
    sed -i -E "s/\"theme\": \"(light|dark|auto)\"/\"theme\": \"$mode\"/" "$HOME/.claude/settings.json"
fi

# Running foot terminals: Noctalia's foot template only affects new windows,
# so recolour the open ones over OSC with the same palette values.
if [ "$1" = day ]; then
    fg=000000; tbg=f2f1e5; c0=deddd1; cn=444444; c8=c8c7bb; cb=222222; c7=000000
else
    fg=f2f1e5; tbg=1c1b16; c0=2e2d26; cn=bbbbaf; c8=3e3d34; cb=ddddd1; c7=f2f1e5
fi
apply_term_colors() {
    printf '\033]10;#%s\007\033]11;#%s\007\033]12;#%s\007' "$fg" "$tbg" "$fg"
    printf '\033]4;0;#%s\007' "$c0"
    for i in 1 2 3 4 5 6; do printf '\033]4;%d;#%s\007' "$i" "$cn"; done
    printf '\033]4;7;#%s\007\033]4;8;#%s\007' "$c7" "$c8"
    for i in 9 10 11 12 13 14; do printf '\033]4;%d;#%s\007' "$i" "$cb"; done
    printf '\033]4;15;#%s\007' "$c7"
}
for pid in $(pgrep -x foot); do
    for child in $(pgrep -P "$pid"); do
        tty=$(readlink /proc/"$child"/fd/0 2>/dev/null)
        case "$tty" in /dev/pts/*) apply_term_colors > "$tty" ;; esac
    done
done
