# dotfiles

Sway desktop configuration for Surface Laptop 4. Color scheme inspired by [williamjansson.com](https://williamjansson.com/files/rice/dots/).

## Contents

- `.config/sway/config` — window manager
- `.config/sway/theme-day.sh` / `theme-night.sh` — day/night theme toggle scripts
- `.config/waybar/` — status bar (style-day.css / style-night.css)
- `.config/foot/foot.ini` — terminal
- `.config/swaylock/config` — lock screen
- `.config/mozilla/firefox/user.js` — Firefox portal theme settings
- `Obsidian Vault/.obsidian/snippets/rice.css` — Obsidian color scheme snippet

## Guides

- [Autodesk Fusion 360 on Arch + Sway](docs/autodesk-fusion-360.md) — running Fusion via Proton, with every non-obvious fix (startup abort, login, the black DXF dialog `Qt6WebEngineCore.dll` patch, and the Wine virtual-desktop fix for the sticky Browser panel).

## Dependencies

```
pacman -S sway waybar foot wmenu swaylock swayidle playerctl \
          xdg-desktop-portal xdg-desktop-portal-gtk
```

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

`Ctrl+Alt+L` — locks via swaylock. Lid close also locks and suspends.
