#!/usr/bin/env bash
# Installer for the Linux (Arch) rice. Symlinks configs into place, installs the
# packages they need, and does the few root-owned bits. Idempotent — safe to
# re-run. The macOS port has its own installer in mac/install.sh.
#
# Configs are SYMLINKED, not copied, so editing ~/.config/sway/config edits the
# repo and `git status` tells the truth. The three derived files the day/night
# toggle overwrites (waybar/style.css, foot/colors.ini, gtk-3.0/gtk.css) are
# seeded as real files instead — linking them would make every toggle write
# through into the repo.

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Symlink $1 -> $2. An existing real file or directory is moved aside to
# .pre-rice first, unless its contents already match what we are linking (the
# common case when migrating a machine that was previously set up by copying).
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

# Copy $1 -> $2 only if $2 is absent. For files the theme toggle owns after
# install: we provide the first one, it rewrites it from then on.
seed() {
    local src="$1" dst="$2"
    mkdir -p "$(dirname "$dst")"
    if [ -e "$dst" ]; then
        echo "  kept:   $dst (theme-owned)"
    else
        cp "$src" "$dst"
        echo "  seeded: $dst"
    fi
}

# ---------------------------------------------------------------- packages ---

PACKAGES=(
    sway hyprland                       # compositors, installed side by side
    waybar foot wmenu                   # bar, terminal, launcher (shared)
    hyprlock swayidle playerctl         # lock + idle (hyprlock under both)
    xdg-desktop-portal xdg-desktop-portal-gtk   # day/night for GTK + Electron
    papirus-icon-theme                  # base for the grey-folder overlay
    thunar gvfs gvfs-smb                # file manager + SMB shares (see docs/)
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

# ------------------------------------------------------------- compositors ---

echo "==> symlinking configs"
link "$REPO_DIR/.config/sway/config"              "$HOME/.config/sway/config"
link "$REPO_DIR/.config/sway/theme-day.sh"        "$HOME/.config/sway/theme-day.sh"
link "$REPO_DIR/.config/sway/theme-night.sh"      "$HOME/.config/sway/theme-night.sh"
link "$REPO_DIR/.config/sway/theme-host.py"       "$HOME/.config/sway/theme-host.py"

link "$REPO_DIR/.config/hypr/hyprland.conf"       "$HOME/.config/hypr/hyprland.conf"
link "$REPO_DIR/.config/hypr/hyprlock.conf"       "$HOME/.config/hypr/hyprlock.conf"
link "$REPO_DIR/.config/hypr/lock.sh"             "$HOME/.config/hypr/lock.sh"
link "$REPO_DIR/.config/hypr/theme-day.sh"        "$HOME/.config/hypr/theme-day.sh"
link "$REPO_DIR/.config/hypr/theme-night.sh"      "$HOME/.config/hypr/theme-night.sh"

link "$REPO_DIR/.config/waybar/config.jsonc"      "$HOME/.config/waybar/config.jsonc"
link "$REPO_DIR/.config/waybar/config-hypr.jsonc" "$HOME/.config/waybar/config-hypr.jsonc"
link "$REPO_DIR/.config/waybar/style-day.css"     "$HOME/.config/waybar/style-day.css"
link "$REPO_DIR/.config/waybar/style-night.css"   "$HOME/.config/waybar/style-night.css"

link "$REPO_DIR/.config/foot/foot.ini"            "$HOME/.config/foot/foot.ini"
link "$REPO_DIR/.config/foot/colors-day.ini"      "$HOME/.config/foot/colors-day.ini"
link "$REPO_DIR/.config/foot/colors-night.ini"    "$HOME/.config/foot/colors-night.ini"

link "$REPO_DIR/.config/gtk-3.0/settings.ini"     "$HOME/.config/gtk-3.0/settings.ini"
link "$REPO_DIR/.config/gtk-3.0/bookmarks"        "$HOME/.config/gtk-3.0/bookmarks"
link "$REPO_DIR/.config/gtk-3.0/gtk-day.css"      "$HOME/.config/gtk-3.0/gtk-day.css"
link "$REPO_DIR/.config/gtk-3.0/gtk-night.css"    "$HOME/.config/gtk-3.0/gtk-night.css"

echo "==> seeding theme-owned files"
seed "$REPO_DIR/.config/waybar/style-day.css"     "$HOME/.config/waybar/style.css"
seed "$REPO_DIR/.config/foot/colors-day.ini"      "$HOME/.config/foot/colors.ini"
seed "$REPO_DIR/.config/gtk-3.0/gtk-day.css"      "$HOME/.config/gtk-3.0/gtk.css"

# ------------------------------------------------------------------- icons ---

echo "==> building Papirus grey-folder overlay themes"
"$REPO_DIR/scripts/papirus-grey-folders.sh"

# ----------------------------------------------------------------- scripts ---

# Helpers the waybar modules shell out to. ~/.local/bin is on PATH; linking
# rather than copying keeps them in step with the repo.
echo "==> scripts"
link "$REPO_DIR/scripts/mem-breakdown" "$HOME/.local/bin/mem-breakdown"

# ----------------------------------------------------------------- firefox ---

# Firefox on this setup keeps its profiles under ~/.config/mozilla/firefox.
# Fall back to the classic ~/.mozilla/firefox for a stock install.
firefox_profile() {
    local home ini p
    for home in "$HOME/.config/mozilla/firefox" "$HOME/.mozilla/firefox"; do
        ini="$home/profiles.ini"
        [ -f "$ini" ] || continue
        # Default= appears under [Install...] (and sometimes [General]) and holds
        # a path relative to the profile home.
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
    link "$REPO_DIR/.config/mozilla/firefox/chrome" "$profile/chrome"
else
    echo "  ! no Firefox profile found — run Firefox once, then re-run this script"
fi

# The native-messaging manifest holds an absolute path to the host script, so it
# is generated rather than checked in. Firefox reads it from ~/.mozilla
# regardless of where the profiles live.
echo "==> firefox theme-switcher native messaging host"
mkdir -p "$HOME/.mozilla/native-messaging-hosts"
cat > "$HOME/.mozilla/native-messaging-hosts/theme_switcher.json" <<EOF
{
  "name": "theme_switcher",
  "description": "Day/night theme switcher host",
  "path": "$HOME/.config/sway/theme-host.py",
  "type": "stdio",
  "allowed_extensions": ["theme-switcher@local"]
}
EOF
echo "  wrote:  ~/.mozilla/native-messaging-hosts/theme_switcher.json"

# ---------------------------------------------------------------- obsidian ---

echo "==> obsidian"
VAULT="$HOME/Obsidian Vault"
if [ -d "$VAULT/.obsidian" ]; then
    link "$REPO_DIR/Obsidian Vault/.obsidian/snippets/rice.css" \
         "$VAULT/.obsidian/snippets/rice.css"
else
    echo "  ! no vault at $VAULT — skipping (copy snippets/rice.css by hand)"
fi

# ------------------------------------------------------------------- fonts ---

echo "==> fonts"
if fc-list | grep -qi "Iosevka Oui"; then
    echo "  Iosevka Oui present"
else
    echo "  ! Iosevka Oui not installed — see README (Font); it is not vendored here"
fi

# ------------------------------------------------------------------ lightdm ---

echo "==> lightdm greeter"
GREETER=/etc/lightdm/lightdm-gtk-greeter.conf
if cmp -s "$REPO_DIR/etc/lightdm-gtk-greeter.conf" "$GREETER"; then
    echo "  already current"
else
    sudo install -Dm 644 "$REPO_DIR/etc/lightdm-gtk-greeter.conf" "$GREETER"
    echo "  installed: $GREETER"
fi

# ------------------------------------------------------------------- theme ---

if [ -n "${WAYLAND_DISPLAY:-}" ]; then
    echo "==> applying the day theme"
    "$HOME/.config/sway/theme-day.sh" || true
fi

cat <<'EOF'

Done. MANUAL steps that remain (see README.md):
  1. Install the Iosevka Oui TTFs, if the font check above flagged them —
     into ~/.local/share/fonts/IosevkaOui and /usr/local/share/fonts/IosevkaOui
     (the second copy is what LightDM uses), then `fc-cache -f`.
  2. Enable the Obsidian snippet: Settings > Appearance > CSS snippets > rice.
  3. Load the Firefox theme extension: about:debugging > This Firefox >
     Load Temporary Add-on > .config/sway/firefox-theme-ext/manifest.json.
  4. Log out and back in — the xdg-desktop-portal environment lines only take
     effect on a fresh session, and the LightDM greeter re-reads its config.
EOF
