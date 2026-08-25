# dotfiles

Sway / Hyprland desktop configuration for Surface Laptop 4. Color scheme inspired by [williamjansson.com](https://williamjansson.com/files/rice/dots/).

Both compositors are configured to look and behave as identically as possible. They are installed side by side and selected at the login screen — see [Switching between Sway and Hyprland](#switching-between-sway-and-hyprland).

## Contents

- `mac/` — **macOS port** (yabai + skhd + Hammerspoon + sketchybar, SIP stays enabled) — see [mac/README.md](mac/README.md)
- `.config/sway/config` — Sway window manager
- `.config/sway/theme-day.sh` / `theme-night.sh` — Sway day/night theme toggle scripts
- `.config/hypr/hyprland.conf` — Hyprland window manager (mirror of the Sway config)
- `.config/hypr/theme-day.sh` / `theme-night.sh` — Hyprland day/night theme toggle scripts
- `.config/waybar/` — status bar; `config.jsonc` (Sway) / `config-hypr.jsonc` (Hyprland), shared `style-day.css` / `style-night.css`
- `.config/foot/foot.ini` — terminal
- `.config/hypr/hyprlock.conf` — lock screen (shared by both) — see [Lock screen](#lock-screen)
- `.config/hypr/lock.sh` — wrapper that launches hyprlock, used by every lock trigger
- `.config/mozilla/firefox/user.js` — Firefox portal theme settings
- `Obsidian Vault/.obsidian/snippets/rice.css` — Obsidian color scheme snippet
- `.config/gtk-3.0/bookmarks` — Thunar sidebar bookmarks (SMB network shares)
- `.config/gtk-3.0/gtk-day.css` / `gtk-night.css` — recoloured Adwaita for GTK apps (Thunar); `gtk.css` is the active copy

## Guides

- [Autodesk Fusion 360 on Arch + Sway](docs/autodesk-fusion-360.md) — running Fusion via Proton, with every non-obvious fix (startup abort, login, the black DXF dialog `Qt6WebEngineCore.dll` patch, and the Wine virtual-desktop fix for the sticky Browser panel).
- [Network drives (SMB) in Thunar](docs/network-drives-smb.md) — browsing/mounting the Unraid SMB shares: the required `gvfs-smb` backend, avahi/mDNS discovery, `.local` resolution, and sidebar bookmarks.

## Dependencies

```
pacman -S sway waybar foot wmenu hyprlock swayidle playerctl \
          xdg-desktop-portal xdg-desktop-portal-gtk
```

For the Hyprland session, additionally:

```
pacman -S hyprland
```

Hyprland reuses the same `swayidle` / `waybar` / `foot` / `wmenu` tools as Sway — no Hyprland-native equivalents needed. The solid background is painted natively by Hyprland (`misc:background_color`), so no wallpaper daemon is required.

The lock screen goes the other way: `hyprlock` is used under Sway too. It speaks plain `ext-session-lock-v1` and needs no Hyprland IPC, so one lock config covers both sessions. swaylock is not used at all — see [Lock screen](#lock-screen) for why.

## Switching between Sway and Hyprland

Both compositors ship a Wayland session file (`sway.desktop`, `hyprland.desktop`)
into `/usr/share/wayland-sessions/`, so once both are installed the LightDM
greeter shows a session picker. Pick **Sway** or **Hyprland** at login — no
toggle script or symlink swapping. Log out to switch.

The two configs are kept deliberately parallel:

| Concern        | Sway                              | Hyprland                                   |
|----------------|-----------------------------------|--------------------------------------------|
| Config         | `.config/sway/config`             | `.config/hypr/hyprland.conf`               |
| Theme toggle   | `.config/sway/theme-*.sh`         | `.config/hypr/theme-*.sh`                  |
| waybar         | `config.jsonc`                    | `config-hypr.jsonc` (launched with `-c`)   |
| Background     | `output * bg` (built in)          | `misc:background_color` (built in)         |
| Idle dpms      | `swaymsg "output * dpms off"`     | `hyprctl dispatch dpms off`                |
| Lock / idle    | hyprlock + swayidle               | hyprlock + swayidle (shared)               |

Keybindings, workspaces, the resize submode, day/night toggle, and window
colors are identical between the two. A few Sway concepts have no exact
Hyprland dispatcher and are mapped to the closest analog (noted in
`hyprland.conf`): `layout stacking`/`tabbed` → window groups, `focus
mode_toggle` and `focus parent` have no equivalent, and the exit binding skips
the swaynag confirmation.

## Font

[Iosevka Oui](https://williamjansson.com/files/rice/dots/fonts/TTF-Unhinted/) — download the TTFs and install:

```
mkdir -p ~/.local/share/fonts/IosevkaOui
cp IosevkaOui-*.ttf ~/.local/share/fonts/IosevkaOui/
fc-cache -f
```

Also install system-wide so LightDM can use it:

```
sudo mkdir -p /usr/local/share/fonts/IosevkaOui
sudo cp IosevkaOui-*.ttf /usr/local/share/fonts/IosevkaOui/
sudo fc-cache -f
```

## Color scheme

Three colors only, from williamjansson's dots:

| Name       | Hex       | Use                        |
|------------|-----------|----------------------------|
| Background | `#f2f1e5` | windows, bar, terminal bg  |
| Accent     | `#deddd1` | title bars, hover states   |
| Foreground | `#000000` | text, borders              |

Night mode inverts to a warm dark palette (`#1c1b16` / `#2e2d26` / `#f2f1e5`).

## Day/night toggle

- `Alt+F5` — night mode
- `Alt+F6` — day mode

Switches live: sway window colors, waybar, foot terminals, Firefox, and any app that respects `prefers-color-scheme` (e.g. Obsidian).

Works via `gsettings set org.gnome.desktop.interface color-scheme` → `xdg-desktop-portal-gtk` → all GTK/Electron apps.

### GTK apps (Thunar, file dialogs)

GTK apps use the stock **Adwaita** theme recoloured with the rice palette via
`~/.config/gtk-3.0/gtk.css`. The toggle scripts copy `gtk-day.css` or
`gtk-night.css` over `gtk.css` and force running GTK apps to reparse by briefly
clearing and resetting `gtk-theme`. Set up on a new machine by copying the
`.config/gtk-3.0/` files into place — no extra packages needed (Adwaita ships
with GTK).

**Icons:** flat **Papirus** with grey folders to match the monochrome look.
The folders come from a user-level overlay theme (`Papirus-Rice` /
`Papirus-Rice-Dark`) that inherits Papirus and symlinks the grey folder variants
— update-safe and no sudo. Set up on a new machine with:

```
sudo pacman -S papirus-icon-theme
scripts/papirus-grey-folders.sh
```

The toggle switches `Papirus-Rice` (day) / `Papirus-Rice-Dark` (night) via
`gsettings`.

### Firefox setup

Copy `.config/mozilla/firefox/user.js` to your Firefox profile directory (`~/.config/mozilla/firefox/<profile>/`) before first launch. This enables portal color scheme detection.

### xdg-desktop-portal setup

The portal must start with the Wayland environment. Add these lines to your sway config's autostart section (already included in this config):

```
exec dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP=sway
exec systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP
```

A full logout/login is required after adding these for the portal to start correctly.

## LightDM greeter

```
sudo mkdir -p /usr/lib/firefox/distribution
sudo cp etc/lightdm-gtk-greeter.conf /etc/lightdm/lightdm-gtk-greeter.conf
```

## Key bindings

| Key | Action |
|-----|--------|
| `Alt+Return` | Terminal (foot) |
| `Alt+C` | Firefox |
| `Alt+O` | Obsidian |
| `Alt+D` | App launcher (wmenu) |
| `Alt+F5` | Night mode |
| `Alt+F6` | Day mode |
| `Ctrl+Alt+L` | Lock screen |

## Obsidian

Copy `Obsidian Vault/.obsidian/snippets/rice.css` to your vault's `.obsidian/snippets/` directory, then enable it in Settings → Appearance → CSS snippets. Uses the same three-color palette as the rest of the desktop and follows the system dark/light mode.

## Lock screen

`Ctrl+Alt+L` — locks via **hyprlock**. Lid close and 5 minutes idle also lock; lid close suspends as well.

The desktop fades to black over 600ms, leaving a single rectangular password field in the middle of the screen. Typing fills it left to right with dots. On a correct password the lock fades back out over 600ms and the desktop fades back in — the session lock is not released until that animation finishes, so there is no flash of desktop before the fade.

Everything goes through `.config/hypr/lock.sh` rather than calling hyprlock directly. It keeps a second lock client from stacking on an existing one, and it backgrounds hyprlock so `swayidle`'s `before-sleep` hook is not blocked until the machine is unlocked (swaylock had `-f` for this; hyprlock has no equivalent). `lock.sh --now` skips the fade, which is what the suspend and lid paths use — a half-faded frame is not what you want left on the panel.

### Why not swaylock

swaylock cannot do either half of the above. Its indicator is a hard-coded ring with no rectangular mode, and it has no fade at all — the `--fade-in` flag belongs to the swaylock-effects fork, not upstream. hyprlock has both natively: `animations:fadeIn` / `fadeOut`, and an `input-field` widget whose `rounding` makes it a rectangle.

### Colours

The lock screen uses the night palette regardless of whether the desktop is in day or night mode, because it fades to black either way and the dark values are the only ones that read on it. The day/night toggle scripts therefore have nothing to rewrite in `hyprlock.conf`.

| Element | Hex |
|---|---|
| Background | `#000000` |
| Field fill | `#1c1b16` |
| Field outline | `#deddd1` |
| Text and dots | `#f2f1e5` |

`rounding = 6` and `outline_thickness = 2` are the same values as `decoration:rounding` and `general:border_size` in `hyprland.conf`, so the field looks like the window borders around it. Failure and "checking" states invert the fill and text colours instead of turning red or green — the palette has no third colour to spend on it.

### PAM

hyprlock authenticates against `/etc/pam.d/hyprlock`. The distro package installs that file, so on Arch there is nothing to do. If it is missing hyprlock falls back to `/etc/pam.d/su`, which authenticates fine but logs an error on every lock.

A source build into a user prefix does not install it — it lands under the prefix, where PAM never looks. Copy it across to silence the error:

```
sudo install -m 644 ~/.local/hypr/etc/pam.d/hyprlock /etc/pam.d/hyprlock
```
