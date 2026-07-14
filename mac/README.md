# mac rice

The Sway rice, ported to macOS (work laptop) with **SIP fully enabled** — no
`csrutil` changes, so it works on managed/corporate machines. Same color
scheme, same Alt-based muscle memory as the Sway/Hyprland configs in
`.config/` at the repo root.

| Sway piece        | macOS analog                                    |
|-------------------|--------------------------------------------------|
| sway (tiling)     | [yabai] (bsp layout, *without* scripting addition) |
| sway (workspaces) | [Hammerspoon] driving native macOS Spaces        |
| bindsym           | [skhd] (windows) + Hammerspoon eventtap (spaces) |
| waybar            | [sketchybar]                                     |
| client borders    | [JankyBorders]                                   |
| wmenu             | [choose]                                         |
| output bg         | solid-color wallpaper via [desktoppr]            |
| Linux Ctrl feel   | [Karabiner-Elements] (Ctrl↔Cmd swap in GUI apps, terminals excluded) |

## Keybinds (same as Sway)

- `Alt+1..0` — switch to workspace N **on the monitor under the cursor**,
  creating it if it doesn't exist.
- `Alt+Shift+1..0` — move focused window to workspace N on its monitor.
- `Alt+j/k/l/;` (and arrows) — focus west/south/north/east; **crosses
  displays at the edge**.
- `Alt+Shift+j/k/l/;` (and arrows) — move window; crosses displays at the edge.
- `Alt+Return` terminal · `Alt+c` browser · `Alt+o` Obsidian · `Alt+d` launcher
- `Alt+Shift+q` close · `Alt+f` fullscreen · `Alt+s/w/e` layouts
- `Alt+r` resize mode · `Alt+Shift+Space` float toggle
- `Alt+Shift+n / Alt+Shift+d` night / day theme

## How workspaces work (the hard-won part)

macOS has no server-side workspace API without disabling SIP, and several
"obvious" approaches are broken on Sequoia (macOS 15). What this config uses,
and why — see `.hammerspoon/init.lua` for the full story:

- **Switching** (`Alt+N`): `hs.spaces.gotoSpace()` — Mission Control
  automation. A brief MC flash, but reliable (incl. empty desktops and
  external monitors). Synthetic swipe-gesture tools (InstantSpaceSwitcher)
  proved flaky; `hs.spaces.moveWindowToSpace()` silently no-ops on Sequoia
  ([Hammerspoon #3698]); yabai needs SIP off for both.
- **Moving windows** (`Alt+Shift+N`): Hammerspoon synthetically grabs the
  window **center** with Ctrl+Cmd held (`NSWindowShouldDragOnGesture` — set by
  install.sh; apps launched before it's set need a relaunch), then posts the
  **native** `Ctrl+(Fn)+Arrow` space-switch — macOS itself carries a held
  window across Spaces. The center grab matters: a titlebar grab breaks on
  apps that draw UI there (Firefox tabs). The `fn` flag is required for
  synthetic arrow-key shortcuts to match. Needs the "Move left/right a space"
  shortcuts enabled (install.sh does this).
- **Creating workspaces**: `hs.spaces.addSpaceToScreen()` — works with SIP on.

## Install

```bash
# core
brew install koekeishiya/formulae/yabai koekeishiya/formulae/skhd
brew install --cask hammerspoon karabiner-elements
# bar, borders, launcher, wallpaper
brew install sketchybar FelixKratz/formulae/borders choose-gui
brew install --cask desktoppr   # or grab from github.com/scriptingosx/desktoppr

./install.sh    # symlinks configs, applies defaults, restarts services
```

Then the manual steps `install.sh` prints at the end:

1. **Accessibility permission** for Hammerspoon, skhd, yabai
   (System Settings > Privacy & Security > Accessibility).
2. **"Displays have separate Spaces"** ON
   (System Settings > Desktop & Dock > Mission Control; logout required).
3. **Reduce Motion** ON for a fast crossfade instead of the slide animation
   (System Settings > Accessibility > Display). Can't be set from the CLI.
4. **Mission Control keyboard shortcuts**: "Switch to Desktop N" entries
   should stay **disabled** (Hammerspoon owns Alt+N; the Ctrl+N defaults are
   unused). "Move left a space" / "Move right a space" must be **enabled**
   (install.sh sets this; verify in System Settings > Keyboard > Shortcuts >
   Mission Control — logout may be needed).
5. **Iosevka Oui** font in `~/Library/Fonts`.
6. iTerm2: set the profile colors to the rice palette so new windows match
   (the theme scripts only recolor open sessions).

## Files

```
skhdrc                     window management keybinds (yabai)
yabairc                    tiling config (bsp, gaps, rules)
.hammerspoon/init.lua      workspace switching / moving / creation
.config/rice/              palette, theme toggles, launcher, wallpapers
.config/sketchybar/        bar config + plugins
.config/borders/           JankyBorders config
.config/karabiner/         Ctrl↔Cmd swap (GUI apps only)
install.sh                 symlinks + system defaults
```

## Known limitations

- No Sway scratchpad (needs yabai's scripting addition → SIP off).
- `Alt+Space` focus mode_toggle and `Alt+a` focus parent have no yabai
  equivalent.
- Workspace switching has a brief Mission Control flash (the price of
  reliability with SIP enabled).
- Karabiner's Ctrl↔Cmd swap means some skhd binds have both `ctrl` and `cmd`
  variants (see lock-screen bind in skhdrc).

[yabai]: https://github.com/koekeishiya/yabai
[skhd]: https://github.com/koekeishiya/skhd
[Hammerspoon]: https://www.hammerspoon.org
[sketchybar]: https://github.com/FelixKratz/SketchyBar
[JankyBorders]: https://github.com/FelixKratz/JankyBorders
[choose]: https://github.com/chipsenkbeil/choose
[desktoppr]: https://github.com/scriptingosx/desktoppr
[Karabiner-Elements]: https://karabiner-elements.pqrs.org
[Hammerspoon #3698]: https://github.com/Hammerspoon/hammerspoon/issues/3698
