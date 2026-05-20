#!/bin/sh
swaymsg "output * bg #1c1b16 solid_color"
swaymsg "client.focused #f2f1e5 #2e2d26 #f2f1e5 #2e2d26 #f2f1e5"
swaymsg "client.unfocused #2e2d26 #1c1b16 #88887e #1c1b16 #2e2d26"
swaymsg "client.focused_inactive #2e2d26 #1c1b16 #88887e #1c1b16 #2e2d26"

cp ~/.config/waybar/style-night.css ~/.config/waybar/style.css
pkill -SIGUSR2 waybar

cat > ~/.config/foot/foot.ini << 'EOF'
[main]
font=Iosevka Oui:size=9

[colors]
alpha=0.95
background=1c1b16
foreground=f2f1e5
cursor=f2f1e5
selection-foreground=1c1b16
selection-background=f2f1e5
regular0=2e2d26
regular1=bbbbaf
regular2=bbbbaf
regular3=bbbbaf
regular4=bbbbaf
regular5=bbbbaf
regular6=bbbbaf
regular7=f2f1e5
bright0=3e3d34
bright1=ddddd1
bright2=ddddd1
bright3=ddddd1
bright4=ddddd1
bright5=ddddd1
bright6=ddddd1
bright7=f2f1e5
EOF

# System color scheme
gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
echo 'user_pref("ui.systemUsesDarkTheme", 1);' > ~/.config/mozilla/firefox/ogg2vqzt.default-release/user.js

# Claude Code theme
sed -i 's/"theme": "light"/"theme": "dark"/' ~/.claude/settings.json

# Apply colors live to all running foot terminals
apply_term_colors() {
    printf '\033]10;#f2f1e5\007'  # foreground
    printf '\033]11;#1c1b16\007'  # background
    printf '\033]12;#f2f1e5\007'  # cursor
    printf '\033]4;0;#2e2d26\007'
    for i in 1 2 3 4 5 6; do printf '\033]4;%d;#bbbbaf\007' $i; done
    printf '\033]4;7;#f2f1e5\007'
    printf '\033]4;8;#3e3d34\007'
    for i in 9 10 11 12 13 14; do printf '\033]4;%d;#ddddd1\007' $i; done
    printf '\033]4;15;#f2f1e5\007'
}

for pid in $(pgrep -x foot); do
    for child in $(pgrep -P "$pid"); do
        tty=$(readlink /proc/"$child"/fd/0 2>/dev/null)
        case "$tty" in /dev/pts/*) apply_term_colors > "$tty" ;; esac
    done
done
