-- Input configuration

hl.config({
    input = {
        -- sensitivity = -0.25,
        accel_profile = "flat",
        follow_mouse = 0, -- rice: focus does not follow the mouse
        touchpad = {
            tap_to_click = true,
            natural_scroll = false,
            disable_while_typing = true,
        },
    },
    -- Software cursors: the hardware cursor plane on the Panther Lake iGPU made the
    -- cursor intermittently vanish or render at the wrong size
    cursor = {
        no_hardware_cursors = 1,
    },
})

hl.gesture({ fingers = 4, direction = "horizontal", action = "workspace" })
hl.gesture({ fingers = 3, direction = "down",       action = "close" })
hl.gesture({ fingers = 3, direction = "up",         action = "fullscreen" })
hl.gesture({ fingers = 3, direction = "left",       action = "float" })
