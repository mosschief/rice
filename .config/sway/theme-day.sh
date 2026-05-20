#!/bin/sh
swaymsg "output * bg #f2f1e5 solid_color"
swaymsg "client.focused #000000 #deddd1 #000000 #deddd1 #000000"
swaymsg "client.unfocused #deddd1 #f2f1e5 #888888 #f2f1e5 #deddd1"
swaymsg "client.focused_inactive #deddd1 #f2f1e5 #888888 #f2f1e5 #deddd1"

cp ~/.config/waybar/style-day.css ~/.config/waybar/style.css
pkill -SIGUSR2 waybar

cat > ~/.config/foot/foot.ini << 'EOF'
[main]
font=Iosevka Oui:size=9

[colors]
alpha=0.95
background=f2f1e5
foreground=000000
cursor=000000
selection-foreground=f2f1e5
selection-background=000000
regular0=deddd1
regular1=444444
regular2=444444
regular3=444444
regular4=444444
regular5=444444
regular6=444444
regular7=000000
bright0=c8c7bb
bright1=222222
bright2=222222
bright3=222222
bright4=222222
bright5=222222
bright6=222222
bright7=000000
EOF

# System color scheme (affects Firefox prefers-color-scheme)
gsettings set org.gnome.desktop.interface color-scheme 'prefer-light'

# Claude Code theme
sed -i 's/"theme": "dark"/"theme": "light"/' ~/.claude/settings.json

# Apply colors live to all running foot terminals
apply_term_colors() {
    printf '\033]10;#000000\007'  # foreground
    printf '\033]11;#f2f1e5\007'  # background
    printf '\033]12;#000000\007'  # cursor
    printf '\033]4;0;#deddd1\007'
    for i in 1 2 3 4 5 6; do printf '\033]4;%d;#444444\007' $i; done
    printf '\033]4;7;#000000\007'
    printf '\033]4;8;#c8c7bb\007'
    for i in 9 10 11 12 13 14; do printf '\033]4;%d;#222222\007' $i; done
    printf '\033]4;15;#000000\007'
}

for pid in $(pgrep -x foot); do
    for child in $(pgrep -P "$pid"); do
        tty=$(readlink /proc/"$child"/fd/0 2>/dev/null)
        case "$tty" in /dev/pts/*) apply_term_colors > "$tty" ;; esac
    done
done
