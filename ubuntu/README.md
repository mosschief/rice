# Ubuntu variant

The [CachyOS variant](../cachyos/README.md) on an Ubuntu 24.04 work laptop (HP
EliteBook 8 G1i). The Hyprland config is the same one: `hyprland.lua`,
`config/*.lua`, `theme.sh`, `lock.sh`, kitty and the palette are linked straight
from `../cachyos`. Everything that differs between the two machines is in
`cachyos/.config/hypr/config/hosts/`, picked by DMI vendor in `config/host.lua`.

## Install

```
sudo apt install just libpipewire-0.3-dev libegl-dev libgles-dev libsecret-1-dev libsodium-dev \
  libpolkit-agent-1-dev libpolkit-gobject-1-dev libcurl4-openssl-dev libwebp-dev libjxl-dev \
  libsndfile1-dev libqalculate-dev libmd4c-dev libical-dev nlohmann-json3-dev libstb-dev \
  libjemalloc-dev libpam0g-dev
~/hypr-build/build-gcc.sh     # GCC 15 into ~/.local/gcc-15, ~40 min, once
~/hypr-build/build.sh         # Hyprland 0.56, Noctalia, wireplumber 0.5 into ~/.local/hypr-0.56
~/rice/ubuntu/install.sh
```

Then log out and pick "Hyprland" at the GDM login screen.

## Why a source build

Noble ships none of it at usable versions. Hyprland's Lua config needs 0.55+,
which needs Lua 5.5 and libstdc++ 15 (noble tops out at GCC 14), and Noctalia
needs wireplumber 0.5 and sdbus-c++ 2. `build-gcc.sh` builds GCC 15 into its
own prefix rather than taking the toolchain PPA, which would replace the
system libstdc++6. Upstream Hyprland is built with GCC 16; one line needs
patching for GCC 15 (`patch_hyprland` in `build.sh`).

Everything links with `DT_RPATH` to the prefix and GCC 15's `lib64`, so the
session sets no `LD_LIBRARY_PATH` and the CachyOS autostart's
`dbus-update-activation-environment --all` is safe here too.

## Differences from the CachyOS machine

| | CachyOS | Ubuntu |
|---|---|---|
| Hyprland | distro package | 0.56.2 from source (`~/hypr-build/build.sh`) |
| Per-machine config | `config/hosts/framework.lua` | `config/hosts/elitebook.lua`: this panel, the ASUS pair at home, the Dell pair at work, nautilus, blueman agent |
| App launch | `uwsm app --` | plain exec (no uwsm; `LAUNCH_PREFIX` in `variables.lua` checks) |
| Lid switch | bound in Hyprland | left to logind, so closing the lid on the dock does not suspend |
| kitty | distro package | upstream 0.49.1 in `~/.local/kitty.app` (noble's 0.32 has no `cursor_trail`) |
| Noctalia screenshots | piped to swash | clipboard + file (no swash); the only difference in `config.toml` |

## Fallback session

The previous build (Hyprland 0.52, hyprlang config) is still in `~/.local/hypr`.
GDM's session entry runs `~/.local/hypr/bin/hyprland-login-session`, which
`build.sh` turns into a selector:

```
echo ~/.local/hypr > ~/.config/hypr/session-prefix   # next login runs 0.52
rm ~/.config/hypr/session-prefix                     # back to 0.56
```

0.52 reads `ubuntu/.config/hypr/hyprland.conf`, a hyprlang translation of the
Lua config frozen at the switch; it is not kept in sync. The session log is
`~/.cache/hyprland/session.log`.
