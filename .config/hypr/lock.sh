#!/bin/sh
# Single entry point for locking, used by the keybinds, the lid switch and
# swayidle in both the Hyprland and Sway sessions.
#
# It lives under .config/hypr/ even though it is compositor-agnostic, because
# hyprlock only ever looks for its own config at <config dir>/hypr/hyprlock.conf
# — the lock's configuration is pinned to this directory whichever compositor is
# running, so the wrapper is kept next to it rather than duplicated per session.
#
# Two things this wrapper exists for:
#
# 1. Idempotence. A second hyprlock stacks another lock client on top of the
#    existing lock; harmless, but it leaves an orphan process behind on every
#    extra keypress. Same guard the old swaylock binding had.
#
# 2. Not blocking swayidle. swayidle holds a systemd sleep inhibitor while its
#    before-sleep command runs, so a foreground lock would postpone suspend
#    until the machine was unlocked again. swaylock had -f to fork once locked;
#    hyprlock has no equivalent, so it is backgrounded here instead.
#
# Usage:
#   lock.sh         fade to black over 600ms (keybind, idle timeout)
#   lock.sh --now   no fade, black on the first frame (before suspend, lid close)
set -eu

if pgrep -x hyprlock >/dev/null; then
    exit 0
fi

case "${1:-}" in
    --now)
        # Suspending mid-fade would freeze the last half-faded frame of the
        # desktop on screen, so skip the fade entirely and force the background
        # to paint on the first frame instead of waiting on resource loading.
        set -- --no-fade-in --immediate-render
        ;;
    *)
        set --
        ;;
esac

hyprlock "$@" &

# Best-effort barrier for the caller. hyprlock exposes no "I am locked" signal,
# so wait for the process to come up and then give it a beat to acquire the
# session lock and commit a frame; otherwise suspend can win the race and the
# desktop is briefly on screen when the machine resumes. Bounded, so a hyprlock
# that dies on a config error cannot wedge suspend here.
i=0
while [ "$i" -lt 20 ]; do
    pgrep -x hyprlock >/dev/null && break
    i=$((i + 1))
    sleep 0.05
done
sleep 0.3
