-- Rice day/night palette (github.com/mosschief/rice)
-- The active mode lives in ~/.local/state/rice-theme ("day" or "night"), written by
-- ~/.config/hypr/theme.sh, which then reloads Hyprland so this file re-reads it.

local function readMode()
    local f = io.open(os.getenv("HOME") .. "/.local/state/rice-theme", "r")
    if not f then return "day" end
    local mode = f:read("*l")
    f:close()
    return mode == "night" and "night" or "day"
end

RICE_MODE = readMode()

local palettes = {
    day   = { bg = "rgb(f2f1e5)", active = "rgb(000000)", inactive = "rgb(deddd1)" },
    night = { bg = "rgb(1c1b16)", active = "rgb(f2f1e5)", inactive = "rgb(2e2d26)" },
}
local p = palettes[RICE_MODE]

hl.config({
    general = {
        col = {
            active_border   = p.active,
            inactive_border = p.inactive,
        },
    },
    group = {
        col = {
            border_active          = p.active,
            border_inactive        = p.inactive,
            border_locked_active   = p.active,
            border_locked_inactive = p.inactive,
        },
        groupbar = {
            col = {
                active          = p.active,
                inactive        = p.inactive,
                locked_active   = p.active,
                locked_inactive = p.inactive,
            },
        },
    },
    misc = {
        background_color = p.bg,
        col = {
            splash = p.active,
        },
    },
})
