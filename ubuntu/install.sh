#!/usr/bin/env bash
# Installer for the Ubuntu variant of the rice: the CachyOS variant on Ubuntu
# 24.04, with Hyprland 0.56, Noctalia and wireplumber 0.5 built from source into
# ~/.local/hypr-0.56. Idempotent — safe to re-run.
#
# The Hyprland config is the CachyOS one, linked straight from ../cachyos:
# config/host.lua picks config/hosts/elitebook.lua on this machine. Only the
# Noctalia config (screenshots) and the 0.52 fallback hyprland.conf live in
# this directory.
#
# Same conventions as ../install.sh: configs are SYMLINKED into ~/.config so
# edits land in the repo, and an existing file that differs is moved aside to
# <name>.pre-rice first.
#
# Nothing here needs root. The compositor and shell are built by
# ~/hypr-build/build-gcc.sh then ~/hypr-build/build.sh; this only checks them.

set -euo pipefail

VARIANT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$VARIANT_DIR")"
CACHY_DIR="$REPO_DIR/cachyos"
PREFIX="${HYPR_PREFIX:-$HOME/.local/hypr-0.56}"

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
  ! Build the compositor and shell first:
      ~/hypr-build/build-gcc.sh && ~/hypr-build/build.sh
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
# The same files cachyos/install.sh links, from the same place.
for f in hyprland.lua xdph.conf lock.sh theme.sh theme-day.sh theme-night.sh config; do
    link "$CACHY_DIR/.config/hypr/$f" "$H/$f"
done
# Only read by the Hyprland 0.52 fallback session (0.56 prefers hyprland.lua).
link "$VARIANT_DIR/.config/hypr/hyprland.conf" "$H/hyprland.conf"

link "$VARIANT_DIR/.config/noctalia/config.toml"     "$HOME/.config/noctalia/config.toml"
link "$CACHY_DIR/.config/noctalia/palettes/rice.json" "$HOME/.config/noctalia/palettes/rice.json"
# Same kitty.conf as CachyOS. Noctalia's kitty template only appends its include
# line when missing, and writes through the link, so linking is safe.
link "$CACHY_DIR/.config/kitty/kitty.conf"           "$HOME/.config/kitty/kitty.conf"
link "$CACHY_DIR/.config/kitty/shaders"              "$HOME/.config/kitty/shaders"
link "$CACHY_DIR/.config/bash/kitty-shake.bash"      "$HOME/.config/bash/kitty-shake.bash"
# The shake shader fires on BEL, which this snippet rings when a command fails.
# Appended once, at the end of ~/.bashrc so it runs after atuin's bash-preexec.
SHAKE_SRC='[ -r ~/.config/bash/kitty-shake.bash ] && . ~/.config/bash/kitty-shake.bash'
if grep -qF "$SHAKE_SRC" "$HOME/.bashrc" 2>/dev/null; then
    echo "  ~/.bashrc already sources kitty-shake.bash"
else
    printf '\n# kitty screen-shake on failed commands (rice)\n%s\n' "$SHAKE_SRC" >> "$HOME/.bashrc"
    echo "  appended: kitty-shake.bash source line to ~/.bashrc"
fi

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

# Re-applies the current mode (default day) so every themed app agrees.
state="${XDG_STATE_HOME:-$HOME/.local/state}"
mode="$(cat "$state/rice-theme" 2>/dev/null || echo day)"
echo "==> applying the $mode theme"
"$HOME/.config/hypr/theme.sh" "$mode" || true

cat <<'EOF'

Done. Log out and back in ("Hyprland" at the GDM login screen) to start
Hyprland 0.56 with the shared Lua config. To go back to the 0.52 build:
  echo ~/.local/hypr > ~/.config/hypr/session-prefix   (undo: rm that file)
EOF
