# CachyOS variant

The rice on top of **CachyOS's stock Hyprland edition** instead of a hand-built
sway/Hyprland setup. CachyOS's defaults are kept — its Lua Hyprland config, the
[Noctalia](https://github.com/noctalia-dev/noctalia) shell as the status bar,
kitty as the terminal, its SUPER bindings and window rules — and the rice's
palette, look, key bindings and day/night toggle are layered over them.

Set up on a Framework Laptop 13 Pro (Intel Core Ultra Series 3) that replaced
the Surface Laptop 4.

## Install

```
git clone https://github.com/mosschief/rice ~/dotfiles
~/dotfiles/cachyos/install.sh
```

Same conventions as the top-level [install.sh](../install.sh): configs are
symlinked into `~/.config`, anything in the way is moved to `<name>.pre-rice`,
and it is safe to re-run. It also downloads Iosevka Oui into
`~/.local/share/fonts/IosevkaOui` if it is missing. Noctalia only reads the font
list at startup, so restart it after a first install (`pkill -x noctalia`, then
`noctalia` from a Hyprland exec or re-login).

## What comes from where

| | CachyOS default (kept) | From the rice |
|---|---|---|
| Status bar | Noctalia, same widgets | Rice palette, square corners, no shadows, workspace numbers, 1px bottom rule, Iosevka Oui |
| Terminal | kitty, cursor trail | Rice palette (via Noctalia's kitty template), 0.95 opacity, no padding, Iosevka Oui 10 |
| Windows | dwindle, window rules (plus a Firefox fullscreen fix), gestures | 2px square borders, 8px gaps, no blur/shadow/transparency |
| Animations | CachyOS springs and slides | Workspace switch is the rice's 100ms fade |
| Keys | All SUPER bindings, media/brightness keys via Noctalia | The whole ALT keymap (below) |
| Launcher | Noctalia launcher | Bound to `Alt+D` in place of wmenu |
| Lock / idle | Noctalia lock screen and idle | Lock at 5 min, screens off at 10, `Ctrl+Alt+L` |
| Input | flat accel | `follow_mouse = 0`, tap-to-click |

`config/colors.lua` (the Cachy greens) is still loaded but no longer referenced;
`config/theme.lua` sets every border colour.

## Theming

Noctalia is the single source of colour. `.config/noctalia/palettes/rice.json`
is a custom palette carrying the rice's day and night values (the same hexes as
`foot/colors-*.ini` and `waybar/style-*.css`), and Noctalia's built-in templates
render it into kitty, GTK 3/4, Qt/KDE and btop. There are no hand-kept
`gtk-*.css` copies in this variant — Noctalia writes `gtk-3.0/noctalia.css`.

`Alt+F5` (night) / `Alt+F6` (day) run `.config/hypr/theme.sh`, which:

1. writes `day`/`night` to `~/.local/state/rice-theme` and reloads Hyprland —
   `config/theme.lua` reads that file for border and background colours;
2. switches Noctalia to the `rice` palette in dark/light mode, which re-renders
   the templates and reloads kitty;
3. sets the solid-colour wallpaper (`wallpapers/rice-*.png`) — Noctalia draws
   the wallpaper, so Hyprland's `misc:background_color` is never visible;
4. sets the Papirus-Rice icon theme when it has been built;
5. writes `~/.config/sway/current-theme` for the Firefox theme-switcher extension;
6. flips the Claude Code theme.

`theme-day.sh` / `theme-night.sh` are kept as thin wrappers so the names match
the other variants.

## Key bindings

ALT is the rice's modifier; CachyOS's SUPER bindings are all still there.

| Key | Action |
|-----|--------|
| `Alt+Return` | Terminal (kitty) |
| `Alt+C` | Firefox |
| `Alt+O` | Obsidian |
| `Alt+D` | Launcher (Noctalia) |
| `Alt+Shift+Q` | Close window |
| `Alt+J/K/L/;`, `Alt+Arrows` | Focus |
| `Alt+Shift+J/K/L/;`, `Alt+Shift+Arrows` | Move window |
| `Alt+H` / `V` / `E` | Flip split |
| `Alt+W` / `S` | Toggle group (≈ sway tabbed/stacking) |
| `Alt+Tab` | Next window in group |
| `Alt+F` | Fullscreen |
| `Alt+Shift+Space` | Toggle floating |
| `Alt+minus` / `Alt+Shift+minus` | Scratchpad show / send |
| `Alt+1…0` / `Alt+Shift+1…0` | Workspace / move to workspace |
| `Alt+R` | Resize mode (J K L ; / arrows, Return or Escape to leave) |
| `Alt+Shift+C` / `R` | Reload |
| `Alt+Shift+E` | Exit |
| `Ctrl+Alt+L` | Lock |
| `Alt+F5` / `Alt+F6` | Night / day |

CachyOS's `ALT+Tab` window cycle is removed in `binds.lua`, since the rice uses
it for groups. `Super+L` locks through `lock.sh` too, so both lock keys behave
the same.

## Hardware-specific bits

These are for the Framework 13 Pro and the two ASUS monitors; change them on
other machines.

- **Monitors** — `config/monitors.lua` / `config/variables.lua`: laptop panel
  (2880x1920 at scale 2, so 1440 logical px wide) on the left, then the
  PA278CV at `1440x0` and the daisy-chained PA278CGV at `4000x0`. The ASUS
  panels are matched by `desc:` for the same reason as in the main config —
  MST renumbers the DP connectors.
- **F5 / F6** — the Framework's top row sends media keys unless Fn is held
  (F5 = `XF86AudioPlay`, F6 = `XF86AudioNext`), so the theme toggle is bound to
  `Alt+` both those and the real F-keys.
- **Keyboard backlight** — `XF86KbdBrightnessUp/Down` and `XF86KbdLightOnOff`
  go to Noctalia (the backlight is `chromeos::kbd_backlight` via `cros_ec`).
- **Cursor** — `no_hardware_cursors = 1` in `config/inputs.lua`: the Panther
  Lake iGPU's hardware cursor plane made the cursor vanish or render at the
  wrong size.

## Lock screen

This variant does **not** use hyprlock. Noctalia takes the session lock itself
before sleep (via a logind inhibitor), so a second ext-session-lock client
races it — with hyprlock in the mix the bar was left frozen after unlock.
`lock.sh` therefore just calls `noctalia msg session lock`; it is kept as the
single entry point so the keybinds and lid switch have one thing to call, and
still accepts `--now` for the lid path. Idle is Noctalia's too (`[idle]` in
`config.toml`): lock after 5 minutes, screens off after 10.

## Firefox fullscreen

`Super+F` / `Alt+F` fullscreen Firefox at the Hyprland level only
(`sync_fullscreen = false` in `windowrules.lua`), so Firefox keeps its tabs and
toolbar instead of entering its own kiosk-style fullscreen.
