-- Rice key bindings (github.com/mosschief/rice), ALT as the modifier.
-- Layered on top of the CachyOS SUPER bindings in binds.lua, which stay for the
-- Noctalia panels, screenshots, zoom, etc. Hardware/media keys are in binds.lua.

local mod = "ALT"
local launchPrefix = "uwsm app -- "
local hypr = os.getenv("HOME") .. "/.config/hypr/"

local left, down, up, right = "J", "K", "L", "semicolon"

-- Digit d -> evdev keycode: 1..9 => 10..18, 0 => 19 (layout-independent)
local function digitCode(d)
    return "code:" .. (d == 0 and 19 or (9 + d))
end

-- Theme
hl.bind(mod .. " + F5", hl.dsp.exec_cmd(hypr .. "theme.sh night"))
hl.bind(mod .. " + F6", hl.dsp.exec_cmd(hypr .. "theme.sh day"))
-- This laptop's F5/F6 send media keys unless Fn is held (F5 = Play, F6 = Next)
hl.bind(mod .. " + XF86AudioPlay", hl.dsp.exec_cmd(hypr .. "theme.sh night"))
hl.bind(mod .. " + XF86AudioNext", hl.dsp.exec_cmd(hypr .. "theme.sh day"))

-- Apps
hl.bind(mod .. " + Return", hl.dsp.exec_cmd(launchPrefix .. TERMINAL))
hl.bind(mod .. " + C",      hl.dsp.exec_cmd(launchPrefix .. BROWSER))
hl.bind(mod .. " + O",      hl.dsp.exec_cmd(launchPrefix .. "obsidian"))
hl.bind(mod .. " + D",      hl.dsp.exec_cmd("noctalia msg panel-toggle launcher"))

-- Kill focused window
hl.bind(mod .. " + SHIFT + Q", hl.dsp.window.close())

-- Focus / move (vim-style J K L ; and arrows)
local dirs = {
    { left,  "Left",  "left",  "l" },
    { down,  "Down",  "down",  "d" },
    { up,    "Up",    "up",    "u" },
    { right, "Right", "right", "r" },
}
for _, d in ipairs(dirs) do
    for _, key in ipairs({ d[1], d[2] }) do
        hl.bind(mod .. " + " .. key,           hl.dsp.focus({ direction = d[3] }))
        hl.bind(mod .. " + SHIFT + " .. key,   hl.dsp.window.move({ direction = d[4] }))
    end
end

-- Split / layout (dwindle auto-splits; these flip the split orientation)
hl.bind(mod .. " + H", hl.dsp.layout("togglesplit"))
hl.bind(mod .. " + V", hl.dsp.layout("togglesplit"))
hl.bind(mod .. " + E", hl.dsp.layout("togglesplit"))
-- sway tabbed/stacking ≈ window groups
hl.bind(mod .. " + W",   hl.dsp.group.toggle())
hl.bind(mod .. " + S",   hl.dsp.group.toggle())
hl.bind(mod .. " + Tab", hl.dsp.group.next())

-- Fullscreen / floating
hl.bind(mod .. " + F",             hl.dsp.window.fullscreen())
hl.bind(mod .. " + SHIFT + Space", hl.dsp.window.float({ action = "toggle" }))

-- Scratchpad -> special workspace
hl.bind(mod .. " + SHIFT + minus", hl.dsp.window.move({ workspace = "special" }))
hl.bind(mod .. " + minus",         hl.dsp.workspace.toggle_special())

-- Workspaces 1-10
for i = 1, 10 do
    local key = digitCode(i % 10)
    hl.bind(mod .. " + " .. key,         hl.dsp.focus({ workspace = i }))
    hl.bind(mod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
end

-- Session
hl.bind(mod .. " + SHIFT + C", hl.dsp.exec_cmd("hyprctl reload"))
hl.bind(mod .. " + SHIFT + R", hl.dsp.exec_cmd("hyprctl reload"))
hl.bind(mod .. " + SHIFT + E", hl.dsp.exit())
hl.bind("CONTROL + " .. mod .. " + L", hl.dsp.exec_cmd(hypr .. "lock.sh"))

-- Drag / resize windows with the modifier held
hl.bind(mod .. " + mouse:272", hl.dsp.window.drag())
hl.bind(mod .. " + mouse:273", hl.dsp.window.resize())

-- Resize mode (ALT+R, then J K L ; / arrows; Return or Escape to leave)
hl.bind(mod .. " + R", hl.dsp.submap("resize"))
hl.define_submap("resize", function()
    local steps = {
        { left,  "Left",  -10,   0 },
        { down,  "Down",    0,  10 },
        { up,    "Up",      0, -10 },
        { right, "Right",  10,   0 },
    }
    for _, s in ipairs(steps) do
        for _, key in ipairs({ s[1], s[2] }) do
            hl.bind(key, hl.dsp.window.resize({ x = s[3], y = s[4], relative = true }), { repeating = true })
        end
    end
    hl.bind("Return", hl.dsp.submap("reset"))
    hl.bind("Escape", hl.dsp.submap("reset"))
end)

-- Lid close -> lock (no fade) then suspend
hl.bind("switch:on:Lid Switch", hl.dsp.exec_cmd(hypr .. "lock.sh --now; systemctl suspend"), { locked = true })
