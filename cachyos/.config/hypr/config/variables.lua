-- Hyprland default apps

TERMINAL     = "kitty"
FILE_MANAGER = "dolphin"
BROWSER      = "firefox"
EDITOR       = "gnome-text-editor --new-window"
CALCULATOR   = "gnome-calculator"

-- Prefix for launched apps: run them as UWSM-managed units where UWSM exists
-- (CachyOS); plain exec elsewhere (Ubuntu has no uwsm).
local function exists(path)
    local f = io.open(path, "r")
    if f then f:close() end
    return f ~= nil
end
LAUNCH_PREFIX = exists("/usr/bin/uwsm") and "uwsm app -- " or ""

-- Workspaces
NUM_WPM = 3 -- Number of workspaces per monitor (Max 10)

-- Per-machine settings (monitors, MONITOR1-3, hardware quirks, app overrides).
-- Loaded here, before binds.lua, because the binds read MONITOR1-3.
require("config.host")
