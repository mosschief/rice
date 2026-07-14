#!/usr/bin/env bash
# dmenu-style app launcher (Sway: Alt+d -> wmenu-run). Lists installed apps and
# opens the chosen one via `choose`. `choose` only themes the match-highlight and
# selected-row background, so we feed it the rice accent/fg; its window background
# is not configurable.

. "${HOME}/.config/rice/colors.sh"

apps=$( { ls -1 /Applications /System/Applications /System/Applications/Utilities "${HOME}/Applications" 2>/dev/null; } \
        | grep '\.app$' | sed 's/\.app$//' | sort -u )

choice=$(printf '%s\n' "$apps" | /opt/homebrew/bin/choose \
            -f "Iosevka Oui" -s 18 -n 12 \
            -b "${RICE_ACCENT}" -c "${RICE_FG}" \
            -p "run:")

[ -n "$choice" ] && open -a "$choice"
