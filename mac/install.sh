#!/usr/bin/env bash
# Installer for the macOS rice. Symlinks configs into place and applies the
# system defaults the setup depends on. Idempotent — safe to re-run.
#
# Prereqs (see README.md): brew packages installed, and the manual System
# Settings steps done (permissions can only be granted by hand).

set -euo pipefail

REPO_MAC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

link() {
    local src="$1" dst="$2"
    mkdir -p "$(dirname "$dst")"
    if [ -e "$dst" ] && [ ! -L "$dst" ]; then
        echo "  backup: $dst -> $dst.pre-rice"
        mv "$dst" "$dst.pre-rice"
    fi
    ln -sfn "$src" "$dst"
    echo "  linked: $dst"
}

echo "==> symlinking configs"
link "$REPO_MAC_DIR/skhdrc"                  "$HOME/.skhdrc"
link "$REPO_MAC_DIR/yabairc"                 "$HOME/.yabairc"
link "$REPO_MAC_DIR/.hammerspoon/init.lua"   "$HOME/.hammerspoon/init.lua"
link "$REPO_MAC_DIR/.config/rice"            "$HOME/.config/rice"
link "$REPO_MAC_DIR/.config/sketchybar"      "$HOME/.config/sketchybar"
link "$REPO_MAC_DIR/.config/borders"         "$HOME/.config/borders"
link "$REPO_MAC_DIR/.config/karabiner/karabiner.json" \
     "$HOME/.config/karabiner/karabiner.json"

echo "==> speeding up Mission Control animation (used by Alt+N space switching)"
defaults write com.apple.dock expose-animation-duration -float 0.1

echo "==> enabling native 'Move left/right a space' shortcuts (Ctrl+Arrow)"
# Required by Alt+Shift+N (Hammerspoon holds the window and posts Ctrl+Fn+Arrow
# so macOS itself carries the window to the next Space). Symbolic hotkeys
# 79/81; params = (char 65535, keycode left=123/right=124, ctrl modifier).
PLIST="$HOME/Library/Preferences/com.apple.symbolichotkeys.plist"
set_hotkey() {
    local id="$1" keycode="$2"
    if ! /usr/libexec/PlistBuddy -c "Set :AppleSymbolicHotKeys:$id:enabled true" "$PLIST" 2>/dev/null; then
        /usr/libexec/PlistBuddy \
            -c "Add :AppleSymbolicHotKeys:$id dict" \
            -c "Add :AppleSymbolicHotKeys:$id:enabled bool true" \
            -c "Add :AppleSymbolicHotKeys:$id:value dict" \
            -c "Add :AppleSymbolicHotKeys:$id:value:type string standard" \
            -c "Add :AppleSymbolicHotKeys:$id:value:parameters array" \
            -c "Add :AppleSymbolicHotKeys:$id:value:parameters:0 integer 65535" \
            -c "Add :AppleSymbolicHotKeys:$id:value:parameters:1 integer $keycode" \
            -c "Add :AppleSymbolicHotKeys:$id:value:parameters:2 integer 8650752" \
            "$PLIST"
    else
        /usr/libexec/PlistBuddy \
            -c "Set :AppleSymbolicHotKeys:$id:value:parameters:0 65535" \
            -c "Set :AppleSymbolicHotKeys:$id:value:parameters:1 $keycode" \
            -c "Set :AppleSymbolicHotKeys:$id:value:parameters:2 8650752" \
            "$PLIST" 2>/dev/null || true
    fi
}
set_hotkey 79 123   # move left a space  (ctrl+left)
set_hotkey 81 124   # move right a space (ctrl+right)
killall cfprefsd 2>/dev/null || true
/System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings -u 2>/dev/null || true

echo "==> restarting Dock (applies animation + hotkey changes; spaces survive)"
killall Dock 2>/dev/null || true

echo "==> starting services"
brew services restart skhd    2>/dev/null || echo "  ! skhd not installed"
brew services restart yabai   2>/dev/null || echo "  ! yabai not installed"
brew services restart sketchybar 2>/dev/null || echo "  ! sketchybar not installed"
brew services restart borders 2>/dev/null || echo "  ! borders not installed"
open -a Hammerspoon 2>/dev/null || echo "  ! Hammerspoon not installed"
open -a Karabiner-Elements 2>/dev/null || echo "  ! Karabiner-Elements not installed"

echo "==> applying the day theme"
"$HOME/.config/rice/theme-day.sh" || true

cat <<'EOF'

Done. MANUAL steps you still need (see README.md for details):
  1. Grant Accessibility permission to Hammerspoon, skhd, and yabai
     (System Settings > Privacy & Security > Accessibility).
  2. Enable "Displays have separate Spaces"
     (System Settings > Desktop & Dock > Mission Control) — needs logout.
  3. Enable Reduce Motion for fast space-switch crossfade
     (System Settings > Accessibility > Display).
  4. If Alt+Shift+N window moves don't work, verify "Move left/right a space"
     shows enabled in System Settings > Keyboard > Shortcuts > Mission Control
     (a logout may be needed for the hotkey change to take effect).
  5. Install the Iosevka Oui font into ~/Library/Fonts (used by sketchybar
     and the launcher).
EOF
