#!/usr/bin/env bash
# Switch the rice to DAY mode (Sway: Alt+F6). Applies live to: macOS appearance,
# JankyBorders, sketchybar. Apps that honor prefers-color-scheme (Firefox,
# Obsidian) follow the macOS appearance automatically.

echo day > "${HOME}/.config/rice/current-theme"
. "${HOME}/.config/rice/colors.sh"

# macOS light appearance
osascript -e 'tell application "System Events" to tell appearance preferences to set dark mode to false' 2>/dev/null

# iTerm: recolor all open sessions to the day palette (bg #f2f1e5, fg #000000).
# (New windows use the profile default until recolored — see notes.)
osascript <<'OSA' 2>/dev/null
tell application "iTerm"
  repeat with w in windows
    repeat with t in tabs of w
      repeat with s in sessions of t
        tell s
          set background color to {62194, 61937, 58853}
          set foreground color to {0, 0, 0}
        end tell
      end repeat
    end repeat
  end repeat
end tell
OSA

# desktop wallpaper: solid rice background (Sway: output * bg #f2f1e5 solid_color)
/usr/local/bin/desktoppr "${HOME}/.config/rice/wallpapers/day.png" 2>/dev/null

# borders (live update on the running instance)
/opt/homebrew/bin/borders active_color="${RICE_BORDER_ARGB}" inactive_color="${RICE_ACCENT_ARGB}" 2>/dev/null

# sketchybar (reload re-reads colors.sh via sketchybarrc)
/opt/homebrew/bin/sketchybar --bar color="${RICE_BG_ARGB}" 2>/dev/null
/opt/homebrew/bin/sketchybar --reload 2>/dev/null
