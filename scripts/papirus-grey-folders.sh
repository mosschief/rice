#!/bin/sh
# Build user-level overlay icon themes that inherit Papirus but recolour the
# folders grey, for the rice. Update-safe (symlinks into the system Papirus, so
# pacman updates to papirus-icon-theme don't reset it) and needs no sudo.
#
# Creates two themes:
#   Papirus-Rice       -> grey folders, inherits Papirus-Light (day)
#   Papirus-Rice-Dark  -> grey folders, inherits Papirus-Dark  (night)
#
# Run once after `pacman -S papirus-icon-theme`. Re-running is safe.

set -e
SRC=/usr/share/icons/Papirus/64x64/places
DEST=~/.local/share/icons

if [ ! -d "$SRC" ]; then
    echo "papirus-icon-theme not installed (missing $SRC)" >&2
    exit 1
fi

build() {
    name="$1"; inherit="$2"
    dir="$DEST/$name"
    rm -rf "$dir"
    mkdir -p "$dir/places@scalable"

    # Map every grey folder variant onto its default name.
    for grey in "$SRC"/folder-grey*.svg; do
        [ -e "$grey" ] || continue
        base=$(basename "$grey" | sed 's/-grey//')   # folder-grey-music.svg -> folder-music.svg
        ln -sf "$grey" "$dir/places@scalable/$base"
    done
    # Plain folder + home aliases.
    ln -sf "$SRC/folder-grey.svg" "$dir/places@scalable/folder.svg"
    [ -e "$SRC/folder-grey.svg" ] && ln -sf "$SRC/folder-grey.svg" "$dir/places@scalable/user-home.svg"
    [ -e "$SRC/folder-grey-desktop.svg" ] && ln -sf "$SRC/folder-grey-desktop.svg" "$dir/places@scalable/user-desktop.svg"

    cat > "$dir/index.theme" << EOF
[Icon Theme]
Name=$name
Comment=Papirus with grey folders (rice overlay)
Inherits=$inherit,Papirus,Adwaita,hicolor

Directories=places@scalable

[places@scalable]
Context=Places
Size=64
MinSize=8
MaxSize=512
Type=Scalable
EOF
    echo "built $name (inherits $inherit)"
}

build Papirus-Rice      Papirus-Light
build Papirus-Rice-Dark Papirus-Dark

gtk-update-icon-cache -f "$DEST/Papirus-Rice" >/dev/null 2>&1 || true
gtk-update-icon-cache -f "$DEST/Papirus-Rice-Dark" >/dev/null 2>&1 || true
echo "done"
