# Ubuntu variant

The [CachyOS variant](../cachyos/README.md) on an Ubuntu 24.04 work laptop (HP
EliteBook 8 G1i): Noctalia as the shell, the rice palette and ALT keymap over
CachyOS's SUPER bindings. Hyprland, wireplumber 0.5 and Noctalia are built from
source into `~/.local/hypr` by `~/hypr-build/build.sh`, because noble packages
none of them at usable versions.

## Install

```
sudo apt install just libpipewire-0.3-dev libegl-dev libgles-dev libsecret-1-dev libsodium-dev \
  libpolkit-agent-1-dev libpolkit-gobject-1-dev libcurl4-openssl-dev libwebp-dev libjxl-dev \
  libsndfile1-dev libqalculate-dev libmd4c-dev libical-dev nlohmann-json3-dev libstb-dev \
  libjemalloc-dev libpam0g-dev
~/hypr-build/build.sh
~/rice/ubuntu/install.sh
```

Then log out and back in to "Hyprland (local build)".

## Differences from the CachyOS variant

| | CachyOS | Ubuntu |
|---|---|---|
| Hyprland config | Lua (`hyprland.lua` + `config/*.lua`) | `hyprland.conf`: Hyprland 0.52 predates Lua config |
| Terminal | kitty | kitty too, but the upstream 0.49.1 build in `~/.local/kitty.app` (noble's 0.32 has no `cursor_trail`); foot stays as a Noctalia-themed fallback |
| Border colours | `config/theme.lua` reads `~/.local/state/rice-theme` | `theme.sh` writes `~/.local/state/rice-theme.conf`, sourced last by `hyprland.conf` |
| Animations | `easy` spring for windows | same leaves and speeds; the spring is a bezier fitted to its step response (0.52 has no springs) |
| Monitors | Framework + ASUS | this laptop's panel, the ASUS pair at home, the Dell pair at work |
| Screenshots | piped to swash | clipboard + file |
| Templates | kitty, alacritty, Qt/KDE, GTK, btop | kitty, foot, GTK, btop |
| Activation env | `dbus-update-activation-environment --all` | only `WAYLAND_DISPLAY` / `XDG_CURRENT_DESKTOP`, so the session's `LD_LIBRARY_PATH` for `~/.local/hypr/lib` does not leak into systemd services |
| Lid switch | bound in Hyprland | left to logind; Noctalia's sleep inhibitor locks first |

Dropped from the CachyOS config: the Steam/gaming window rules, per-monitor
`SUPER+1..3` binds, and expression-based window sizes (percentages instead).

`lock.sh`, `theme-day.sh`, `theme-night.sh`, the palette and the wallpapers are
linked straight from `../cachyos`, so there is one copy of each.

## Lock screen

Noctalia's lock authenticates against `/etc/pam.d/login`, which Ubuntu ships,
so domain (SSSD) accounts work the same as at the console. hyprlock is still
built but no longer used; waybar, swayidle and wmenu are no longer started.
