#!/usr/bin/env bash
# Installer for the Ubuntu variant of the rice: the CachyOS variant (Noctalia
# shell, rice palette and ALT keymap layered over CachyOS's SUPER bindings) on
# Ubuntu 24.04 with Hyprland 0.52 built from source into ~/.local/hypr.
# Idempotent — safe to re-run.
#
# Same conventions as ../install.sh: configs are SYMLINKED into ~/.config so
# edits land in the repo, and an existing file that differs is moved aside to
# <name>.pre-rice first. Files shared with the CachyOS variant (palette,
# wallpapers, lock.sh, theme-day/night.sh) are linked from ../cachyos directly.
#
# Nothing here needs root. Hyprland, wireplumber 0.5 and Noctalia are built by
# ~/hypr-build/build.sh; this script only checks that they are there.

set -euo pipefail

VARIANT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$VARIANT_DIR")"
CACHY_DIR="$REPO_DIR/cachyos"
PREFIX="${HYPR_PREFIX:-$HOME/.local/hypr}"

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

# ------------------------------------------------------------------ binaries ---

echo "==> binaries"
missing=0
for b in Hyprland hyprctl noctalia; do
    if [ -x "$PREFIX/bin/$b" ]; then
        echo "  ok:      $PREFIX/bin/$b"
    else
        echo "  MISSING: $PREFIX/bin/$b"; missing=1
    fi
done
for b in jq gsettings; do
    command -v "$b" >/dev/null && echo "  ok:      $b" || { echo "  MISSING: $b"; missing=1; }
done
if [ "$missing" -eq 1 ]; then
    cat <<'EOF'
  ! Build the compositor and shell first:  ~/hypr-build/build.sh
    (Noctalia's apt build-dependencies are listed in ubuntu/README.md.)
EOF
fi

# ------------------------------------------------------------------- kitty ---

# Upstream prebuilt kitty in ~/.local/kitty.app: noble's apt kitty is 0.32,
# which predates cursor_trail (0.37). Pinned, and checked against the digest
# GitHub publishes for the release asset.
KITTY_VERSION=0.49.1
KITTY_SHA256=8cfd68ed484d9a32e4e389abffe1a0ec6e0fbd7be5c9ea1c4fa41b9ead4af791
echo "==> kitty"
if [ "$("$HOME/.local/kitty.app/bin/kitty" --version 2>/dev/null | awk '{print $2}')" = "$KITTY_VERSION" ]; then
    echo "  kitty $KITTY_VERSION present"
else
    tmp="$(mktemp -d)"
    curl -fsSL -o "$tmp/kitty.txz" \
        "https://github.com/kovidgoyal/kitty/releases/download/v$KITTY_VERSION/kitty-$KITTY_VERSION-x86_64.txz"
    echo "$KITTY_SHA256  $tmp/kitty.txz" | sha256sum -c --quiet
    rm -rf "$HOME/.local/kitty.app" && mkdir -p "$HOME/.local/kitty.app"
    tar -xJf "$tmp/kitty.txz" -C "$HOME/.local/kitty.app"
    rm -rf "$tmp"
    echo "  installed: ~/.local/kitty.app (kitty $KITTY_VERSION)"
fi
mkdir -p "$HOME/.local/bin" "$HOME/.local/share/applications"
ln -sfn "$HOME/.local/kitty.app/bin/kitty"  "$HOME/.local/bin/kitty"
ln -sfn "$HOME/.local/kitty.app/bin/kitten" "$HOME/.local/bin/kitten"
sed -e "s|Icon=kitty|Icon=$HOME/.local/kitty.app/share/icons/hicolor/256x256/apps/kitty.png|" \
    -e "s|Exec=kitty|Exec=$HOME/.local/kitty.app/bin/kitty|" \
    "$HOME/.local/kitty.app/share/applications/kitty.desktop" \
    > "$HOME/.local/share/applications/kitty.desktop"

# ------------------------------------------------------------------ configs ---

echo "==> symlinking configs"
H="$HOME/.config/hypr"
link "$VARIANT_DIR/.config/hypr/hyprland.conf"   "$H/hyprland.conf"
link "$VARIANT_DIR/.config/hypr/theme.sh"        "$H/theme.sh"
link "$CACHY_DIR/.config/hypr/lock.sh"           "$H/lock.sh"
link "$CACHY_DIR/.config/hypr/theme-day.sh"      "$H/theme-day.sh"
link "$CACHY_DIR/.config/hypr/theme-night.sh"    "$H/theme-night.sh"

link "$VARIANT_DIR/.config/noctalia/config.toml"     "$HOME/.config/noctalia/config.toml"
link "$CACHY_DIR/.config/noctalia/palettes/rice.json" "$HOME/.config/noctalia/palettes/rice.json"
# Same kitty.conf as CachyOS. Noctalia's kitty template only appends its include
# line when missing, and writes through the link, so linking is safe.
link "$CACHY_DIR/.config/kitty/kitty.conf"           "$HOME/.config/kitty/kitty.conf"
# foot is kept as a fallback terminal, still themed by Noctalia.
link "$VARIANT_DIR/.config/foot/foot.ini"            "$HOME/.config/foot/foot.ini"

link "$CACHY_DIR/wallpapers/rice-day.png"   "$HOME/.local/share/wallpapers/rice-day.png"
link "$CACHY_DIR/wallpapers/rice-night.png" "$HOME/.local/share/wallpapers/rice-night.png"

# GTK: Noctalia owns the colours now (gtk-3.0/noctalia.css, imported from
# gtk.css). The old hand-recoloured gtk.css from the sway/waybar setup would
# sit underneath it, so move it aside once.
if [ -f "$HOME/.config/gtk-3.0/gtk.css" ] && ! grep -q noctalia.css "$HOME/.config/gtk-3.0/gtk.css"; then
    echo "  backup: ~/.config/gtk-3.0/gtk.css -> gtk.css.pre-rice"
    mv "$HOME/.config/gtk-3.0/gtk.css" "$HOME/.config/gtk-3.0/gtk.css.pre-rice"
fi

# ------------------------------------------------------------------- icons ---

if [ -d /usr/share/icons/Papirus ]; then
    echo "==> building Papirus grey-folder overlay themes"
    "$REPO_DIR/scripts/papirus-grey-folders.sh"
fi

# ------------------------------------------------------------------- fonts ---

echo "==> fonts"
FONT_DIR="$HOME/.local/share/fonts/IosevkaOui"
FONT_URL="https://williamjansson.com/files/rice/dots/fonts/TTF-Unhinted"
if fc-list | grep -i "Iosevka Oui" >/dev/null; then  # not -q: it closes the pipe early and pipefail trips on fc-list's SIGPIPE
    echo "  Iosevka Oui present"
else
    mkdir -p "$FONT_DIR"
    for s in Regular Bold Light Extended ExtendedBold ExtendedLight SemiExtended SemiExtendedBold SemiExtendedLight; do
        curl -fsSL -o "$FONT_DIR/IosevkaOui-$s.ttf" "$FONT_URL/IosevkaOui-$s.ttf"
    done
    fc-cache -f "$FONT_DIR"
    echo "  installed: $FONT_DIR (restart Noctalia to pick it up)"
fi

# ------------------------------------------------------------------- theme ---

# Seeds ~/.local/state/rice-theme.conf, which hyprland.conf sources; keeps the
# current mode if one was already chosen.
state="${XDG_STATE_HOME:-$HOME/.local/state}"
mode="$(cat "$state/rice-theme" 2>/dev/null || echo day)"
echo "==> applying the $mode theme"
"$HOME/.config/hypr/theme.sh" "$mode" || true

cat <<'EOF'

Done. Log out and back in to "Hyprland (local build)" to start Noctalia in
place of waybar/swayidle/hyprlock (or, in a running session: pkill waybar;
pkill swayidle; hyprctl reload; hyprctl dispatch exec noctalia).
EOF
