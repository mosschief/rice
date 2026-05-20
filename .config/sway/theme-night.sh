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
