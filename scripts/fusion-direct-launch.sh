#!/bin/bash
# Reliable direct Proton launcher for Autodesk Fusion (bypasses the buggy
# bundled autodesk_fusion_launcher.sh which starts full Steam and runs
# `wineserver -k` right after `proton run`, killing Fusion mid-boot).
#
# Notes:
#  - Qt6WebEngineCore.dll is patched (INT3->NOP) so export/save dialogs work.
#  - GE-Proton10-Fusion is the runtime; the prefix is ~/.autodesk_fusion/protonprefix.

set -u
PROTON_DIR="$HOME/.local/share/Steam/compatibilitytools.d/GE-Proton10-Fusion"
PREFIX="$HOME/.autodesk_fusion/protonprefix"

export STEAM_COMPAT_CLIENT_INSTALL_PATH="$HOME/.local/share/Steam"
export STEAM_COMPAT_DATA_PATH="$PREFIX"
export PROTON_LOG=0

FUSION="$(find "$PREFIX/pfx" -name Fusion360.exe -path '*production*' 2>/dev/null | head -1)"
if [ -z "$FUSION" ]; then
    echo "Fusion360.exe not found in $PREFIX/pfx" >&2
    exit 1
fi

# Wine runs Fusion inside a virtual desktop (registry: HKCU\Software\Wine\
# Explorer\Desktop=Default) so its Browser panel / dialogs stay contained and
# don't leak onto other Sway workspaces. Size that desktop to the CURRENT
# focused output's logical resolution so it fits whatever display Fusion opens
# on (laptop panel or an external monitor plugged in). Falls back to the
# XWayland root size, then 1289x859.
RES="$(swaymsg -t get_outputs 2>/dev/null | python3 -c '
import json,sys
try: outs=json.load(sys.stdin)
except Exception: sys.exit()
cand=[o for o in outs if o.get("focused")] or [o for o in outs if o.get("active")] or outs
if cand:
    r=cand[0].get("rect") or {}
    if r.get("width") and r.get("height"): print("%dx%d" % (r["width"], r["height"]))
' 2>/dev/null)"
if [ -z "$RES" ] && command -v xwininfo >/dev/null 2>&1; then
    RES="$(DISPLAY=:0 xwininfo -root 2>/dev/null | awk '/-geometry/{print $2}' | grep -oE '^[0-9]+x[0-9]+')"
fi
[ -z "$RES" ] && RES="1289x859"
WINEPREFIX="$PREFIX/pfx" "$PROTON_DIR/files/bin/wine" reg add \
    'HKCU\Software\Wine\Explorer\Desktops' /v Default /t REG_SZ /d "$RES" /f >/dev/null 2>&1
echo "Virtual desktop sized to $RES" >&2

# Clean up any stale processes from a previous run in this prefix (also reaps
# the short-lived wineserver started by the reg add above).
WINEPREFIX="$PREFIX/pfx" "$PROTON_DIR/files/bin/wineserver" -k 2>/dev/null
sleep 2

# The Proton startup occasionally aborts with "double free or corruption"
# before Fusion's window appears. Detect that (proton run returns in < 25s
# with no Fusion window) and retry up to 3 times.
for attempt in 1 2 3; do
    start=$(date +%s)
    "$PROTON_DIR/proton" run "$FUSION"
    rc=$?
    elapsed=$(( $(date +%s) - start ))
    # If it ran for a meaningful time, this was a normal session (user quit) -> done.
    if [ "$elapsed" -ge 25 ]; then
        break
    fi
    echo "Fusion exited after ${elapsed}s (rc=$rc) — likely the startup crash; retrying ($attempt/3)..." >&2
    WINEPREFIX="$PREFIX/pfx" "$PROTON_DIR/files/bin/wineserver" -k 2>/dev/null
    sleep 2
done
