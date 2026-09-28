-- Framework Laptop 13 Pro (Intel Core Ultra Series 3), CachyOS.
-- Moved here unchanged from variables.lua, monitors.lua, inputs.lua and
-- rice_binds.lua when the config was shared with the Ubuntu laptop.

-- Rice layout: laptop (left) -> PA278CV (middle) -> PA278CGV (right, daisy-chained)
-- External monitors are matched by description, not connector name, since MST
-- daisy-chaining renumbers connectors (DP-2/DP-4/...) across reconnects/reboots.
-- The laptop panel is 2880x1920 at scale 2 = 1440 logical px wide, so the
-- externals start at x=1440 (the Surface's 1410 was its 2256px panel at 1.6).
MONITOR1 = "eDP-1"
MONITOR2 = "desc:ASUSTek COMPUTER INC PA278CV W3LMQV029417"
MONITOR3 = "desc:ASUSTek COMPUTER INC PA278CGV TCLMQV045359"
PRIMARY_MONITOR = MONITOR1

hl.monitor({ output = MONITOR1, mode = "preferred",       position = "0x0",    scale = "2" })
hl.monitor({ output = MONITOR2, mode = "2560x1440@74.92", position = "1440x0", scale = "1" })
hl.monitor({ output = MONITOR3, mode = "preferred",       position = "4000x0", scale = "1" })

-- Software cursors: the hardware cursor plane on the Panther Lake iGPU made the
-- cursor intermittently vanish or render at the wrong size
hl.config({ cursor = { no_hardware_cursors = 1 } })

-- Lid close -> lock (no fade) then suspend
hl.bind("switch:on:Lid Switch",
    hl.dsp.exec_cmd(os.getenv("HOME") .. "/.config/hypr/lock.sh --now; systemctl suspend"),
    { locked = true })
