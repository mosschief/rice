-- HP EliteBook 8 G1i (work laptop), Ubuntu 24.04, Hyprland built from source
-- by ~/hypr-build/build.sh.

-- Apps that differ from the CachyOS defaults in variables.lua
FILE_MANAGER = "nautilus"

-- Monitors. The panel is 1920x1200 at scale 1, so externals start at x=1920.
-- Externals are matched by desc: (model + serial): MST daisy-chaining at home
-- and evdi (DisplayLink) at work both renumber connectors across replugs.
--   eDP-1          0 -> 1920    (1920x1200 @ 1)
--   middle         1920 -> 4480 (2560x1440)
--   right          4480 -> 7040 (2560x1440)
MONITOR1 = "eDP-1"
MONITOR2 = "desc:ASUSTek COMPUTER INC PA278CV W3LMQV029417"   -- home
MONITOR3 = "desc:ASUSTek COMPUTER INC PA278CGV TCLMQV045359"  -- home
PRIMARY_MONITOR = MONITOR1

hl.monitor({ output = MONITOR1, mode = "preferred",       position = "0x0",    scale = "1" })
hl.monitor({ output = MONITOR2, mode = "2560x1440@74.92", position = "1920x0", scale = "1" })
hl.monitor({ output = MONITOR3, mode = "preferred",       position = "4480x0", scale = "1" })
-- Work desk: HP USB-C/A Universal Dock G2. Its DP outputs are DisplayLink
-- (evdi), so if these are dark check `lsmod | grep evdi` before this file.
-- Both are the same model, so only the serial tells them apart.
hl.monitor({ output = "desc:Dell Inc. DELL P2725DE D1X9K84", mode = "preferred", position = "1920x0", scale = "1" })
hl.monitor({ output = "desc:Dell Inc. DELL P2725DE 4L68074", mode = "preferred", position = "4480x0", scale = "1" })

-- Lid: left to systemd-logind (HandleLidSwitch=suspend, HandleLidSwitchDocked=
-- ignore), so closing the lid on the dock does not suspend. Noctalia takes the
-- session lock before sleep through a logind inhibitor.

-- The padlock key emits no evdev keycode (the HP embedded controller consumes
-- it), so Super+L in binds.lua is the only lock key besides Ctrl+Alt+L.

hl.on("hyprland.start", function()
    -- blueman-applet registers the Bluetooth pairing agent (PIN/confirm dialogs)
    hl.exec_cmd(os.getenv("HOME") .. "/.config/hypr/blueman-applet-keepalive.sh")
end)
