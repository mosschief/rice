-- Look and feel configuration (rice: square, flat, no blur/shadow/transparency)
-- Border colours are set per day/night mode in theme.lua

hl.config({
    general = {
        gaps_in = 4,      -- rice: 8px between windows
        gaps_out = 8,
        border_size = 2,
        layout = "dwindle",
        extend_border_grab_area = 10,
        resize_on_border = true,
    },
    decoration = {
        dim_special = 0.3,
        rounding = 0,
        active_opacity = 1,
        inactive_opacity = 1,
        fullscreen_opacity = 1,
        blur = {
            enabled = false,
        },
        shadow = {
            enabled = false,
        },
    },
})
