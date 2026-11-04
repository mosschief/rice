#!/usr/bin/env bash
# Installer for the CachyOS variant of the rice: CachyOS's stock Hyprland (Lua
# config) + Noctalia shell + kitty, restyled and rebound to match the sway /
# Hyprland rice at the top of this repo. Idempotent — safe to re-run.
#
# Same conventions as ../install.sh: configs are SYMLINKED into ~/.config so
# edits land in the repo, and an existing file that differs is moved aside to
# <name>.pre-rice first.

set -euo pipefail

VARIANT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$VARIANT_DIR")"

link() {
    local src="$1" dst="$2"
    mkdir -p "$(dirname "$dst")"
    if [ -e "$dst" ] && [ ! -L "$dst" ]; then
        if diff -rq "$src" "$dst" >/dev/null 2>&1; then
            rm -rf "$dst"
        else
            echo "  backup: $dst -> $dst.pre-rice"
            mv "$dst" "$dst.pre-rice"
        fi
    fi
    ln -sfn "$src" "$dst"
    echo "  linked: $dst"
}

# ---------------------------------------------------------------- packages ---

# hyprland, noctalia and kitty come with CachyOS's Hyprland edition.
PACKAGES=(
    hyprland noctalia kitty             # lock screen and idle are Noctalia's too
    xdg-desktop-portal-gtk              # day/night for GTK + Firefox
    papirus-icon-theme                  # base for the grey-folder overlay
)

echo "==> packages"
missing=()
for p in "${PACKAGES[@]}"; do
    pacman -Qq "$p" >/dev/null 2>&1 || missing+=("$p")
done
if [ ${#missing[@]} -eq 0 ]; then
    echo "  all present"
else
    echo "  installing: ${missing[*]}"
    sudo pacman -S --needed "${missing[@]}"
fi

# ------------------------------------------------------------------ configs ---

echo "==> symlinking configs"
H="$VARIANT_DIR/.config/hypr"
for f in hyprland.lua xdph.conf lock.sh theme.sh theme-day.sh theme-night.sh config; do
    link "$H/$f" "$HOME/.config/hypr/$f"
done

link "$VARIANT_DIR/.config/noctalia/config.toml"       "$HOME/.config/noctalia/config.toml"
link "$VARIANT_DIR/.config/noctalia/palettes/rice.json" "$HOME/.config/noctalia/palettes/rice.json"
# Noctalia's kitty template only writes kitty.conf when the include line is
# missing, and writes through the link when it does, so linking is safe.
link "$VARIANT_DIR/.config/kitty/kitty.conf"           "$HOME/.config/kitty/kitty.conf"
link "$VARIANT_DIR/.config/kitty/shaders"              "$HOME/.config/kitty/shaders"

link "$VARIANT_DIR/wallpapers/rice-day.png"   "$HOME/.local/share/wallpapers/rice-day.png"
link "$VARIANT_DIR/wallpapers/rice-night.png" "$HOME/.local/share/wallpapers/rice-night.png"

# ------------------------------------------------------------------- icons ---

if pacman -Qq papirus-icon-theme >/dev/null 2>&1; then
    echo "==> building Papirus grey-folder overlay themes"
    "$REPO_DIR/scripts/papirus-grey-folders.sh"
fi

# ----------------------------------------------------------------- firefox ---

firefox_profile() {
    local home ini p
    for home in "$HOME/.config/mozilla/firefox" "$HOME/.mozilla/firefox"; do
        ini="$home/profiles.ini"
        [ -f "$ini" ] || continue
        while IFS= read -r p; do
            [ -n "$p" ] && [ -d "$home/$p" ] && { printf '%s\n' "$home/$p"; return 0; }
        done < <(sed -n 's/^Default=//p' "$ini")
    done
    return 1
}

echo "==> firefox"
if profile="$(firefox_profile)"; then
    echo "  profile: $profile"
    link "$REPO_DIR/.config/mozilla/firefox/user.js" "$profile/user.js"
    link "$REPO_DIR/.config/mozilla/firefox/chrome"  "$profile/chrome"
else
    echo "  ! no Firefox profile found — run Firefox once, then re-run this script"
fi

# theme.sh writes ~/.config/sway/current-theme, which this host watches.
mkdir -p "$HOME/.mozilla/native-messaging-hosts"
cat > "$HOME/.mozilla/native-messaging-hosts/theme_switcher.json" <<EOF
{
  "name": "theme_switcher",
  "description": "Day/night theme switcher host",
  "path": "$REPO_DIR/.config/sway/theme-host.py",
  "type": "stdio",
  "allowed_extensions": ["theme-switcher@local"]
}
EOF
echo "  wrote:  ~/.mozilla/native-messaging-hosts/theme_switcher.json"

# ------------------------------------------------------------------- fonts ---

echo "==> fonts"
# Nordwand Mono (https://github.com/tywr/Nordwand-Mono, OFL-1.1). Pinned
# release, checked against the digest GitHub publishes for the asset.
NORDWAND_VERSION=1.3.2
NORDWAND_SHA256=2359518a2e6c74f50a89125730772e68de6c887951ff414e11b47ea528ce6a8a
FONT_DIR="$HOME/.local/share/fonts/NordwandMono"
if fc-list | grep -i "Nordwand Mono" >/dev/null; then  # not -q: it closes the pipe early and pipefail trips on fc-list's SIGPIPE
    echo "  Nordwand Mono present"
else
    tmp="$(mktemp -d)"
    curl -fsSL -o "$tmp/nordwand.zip" \
        "https://github.com/tywr/Nordwand-Mono/releases/download/$NORDWAND_VERSION/NordwandMono-TTF.zip"
    echo "$NORDWAND_SHA256  $tmp/nordwand.zip" | sha256sum -c --quiet
    mkdir -p "$FONT_DIR"
    python3 -m zipfile -e "$tmp/nordwand.zip" "$tmp/ttf"
    find "$tmp/ttf" -name '*.ttf' -exec cp {} "$FONT_DIR/" \;
    rm -rf "$tmp"
    fc-cache -f "$FONT_DIR"
    echo "  installed: $FONT_DIR (restart Noctalia to pick it up)"
fi

# ------------------------------------------------------------------- theme ---

if [ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]; then
    echo "==> applying the day theme"
    "$HOME/.config/hypr/theme.sh" day || true
fi

cat <<'EOF'

Done. MANUAL steps that remain (see cachyos/README.md):
  1. monitors.lua / variables.lua / the F5-F6 and keyboard-backlight binds are
     for a Framework Laptop 13 Pro — adjust them for other hardware.
  2. Load the Firefox theme extension: about:debugging > This Firefox >
     Load Temporary Add-on > .config/sway/firefox-theme-ext/manifest.json.
EOF
