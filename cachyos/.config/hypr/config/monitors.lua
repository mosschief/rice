-- Monitor wiki https://wiki.hypr.land/Configuring/Basics/Monitors/
-- Rice layout (github.com/mosschief/rice): laptop (left) -> PA278CV (middle) -> PA278CGV (right, daisy-chained)
-- External monitors are matched by description, not connector name, since MST
-- daisy-chaining renumbers connectors (DP-2/DP-4/...) across reconnects/reboots.
-- The laptop panel is 2880x1920 at scale 2 = 1440 logical px wide, so the
-- externals start at x=1440 (the Surface's 1410 was its 2256px panel at 1.6).

hl.monitor({ output = MONITOR1, mode = "preferred",       position = "0x0",    scale = "2" })
hl.monitor({ output = MONITOR2, mode = "2560x1440@74.92", position = "1440x0", scale = "1" })
hl.monitor({ output = MONITOR3, mode = "preferred",       position = "4000x0", scale = "1" })

-- Anything else: to the right, native scale
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = "1" })
