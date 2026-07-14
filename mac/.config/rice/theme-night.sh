#!/usr/bin/env bash
# Switch the rice to NIGHT mode (Sway: Alt+F5). Applies live to: macOS appearance,
# JankyBorders, sketchybar. Apps that honor prefers-color-scheme (Firefox,
# Obsidian) follow the macOS appearance automatically.

echo night > "${HOME}/.config/rice/current-theme"
. "${HOME}/.config/rice/colors.sh"

# macOS dark appearance
osascript -e 'tell application "System Events" to tell appearance preferences to set dark mode to true' 2>/dev/null

# iTerm: recolor all open sessions to the night palette (bg #1c1b16, fg #f2f1e5).
# (New windows use the profile default until recolored — see notes.)
osascript <<'OSA' 2>/dev/null
tell application "iTerm"
  repeat with w in windows
    repeat with t in tabs of w
      repeat with s in sessions of t
        tell s
          set background color to {7196, 6939, 5654}
          set foreground color to {62194, 61937, 58853}
        end tell
      end repeat
    end repeat
  end repeat
end tell
OSA

# desktop wallpaper: solid rice background (night)
/usr/local/bin/desktoppr "${HOME}/.config/rice/wallpapers/night.png" 2>/dev/null

# borders (live update on the running instance)
/opt/homebrew/bin/borders active_color="${RICE_FG_ARGB}" inactive_color="${RICE_ACCENT_ARGB}" 2>/dev/null

# sketchybar (reload re-reads colors.sh via sketchybarrc)
/opt/homebrew/bin/sketchybar --bar color="${RICE_BG_ARGB}" 2>/dev/null
/opt/homebrew/bin/sketchybar --reload 2>/dev/null
