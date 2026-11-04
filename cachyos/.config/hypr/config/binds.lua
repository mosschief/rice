-- Base layer modifier. Flipped from SUPER to ALT so the whole desktop uses ALT.
-- rice_binds.lua (also ALT, loaded after this file) is the authority on every
-- chord the two share; the colliding base binds below were removed so rice wins.
-- SUPER no longer drives any window-manager action.
local mainMod = "ALT"
local noctCall = "noctalia msg "
local launchPrefix = LAUNCH_PREFIX -- config/variables.lua: uwsm where available

-- AZERTY fix: the number-row keys emit symbols (& é " ' ...) without Shift, so
-- binding to the digit characters fails. Bind by physical keycode instead.
-- Digit d -> evdev keycode: 1..9 => 10..18, 0 => 19
local function digitCode(d)
    return "code:" .. (d == 0 and 19 or (9 + d))
end

---------------------------
---- WINDOW MANAGEMENT ----
---------------------------

-- Window manipulation
hl.bind(mainMod .. " + Escape",      hl.dsp.exec_cmd("hyprctl kill"))
hl.bind(mainMod .. " + Q",           hl.dsp.window.close())
-- Removed (rice_binds wins): ALT+Space float (was SUPER+ALT), ALT+D fullscreen
-- mode 1, ALT+F fullscreen, ALT+J togglesplit. rice has float on ALT+SHIFT+Space,
-- fullscreen on ALT+F, togglesplit on ALT+H/V/E.

-- Change focus
-- Removed (rice_binds wins): ALT+Left/Right/Up/Down focus. rice binds the same
-- arrows plus J/K/L/semicolon to focus.
-- Removed (rice_binds wins): ALT+Tab. rice uses ALT+Tab for group.next.

-- Move active window around workspaces & monitors
-- Removed (rice_binds wins): ALT+SHIFT+Up/Right/Left/Down window move, and
-- ALT+SHIFT+<digit> (rice moves the window to that workspace instead of a monitor).
hl.bind(mainMod .. " + SHIFT + mouse_up",             hl.dsp.window.move({ monitor   = "-1" }))
hl.bind(mainMod .. " + SHIFT + mouse_down",           hl.dsp.window.move({ monitor   = "+1" }))
hl.bind(mainMod .. " + CONTROL + SHIFT + Right",      hl.dsp.window.move({ workspace = "m+1" }))
hl.bind(mainMod .. " + CONTROL + SHIFT + Left",       hl.dsp.window.move({ workspace = "m-1" }))
hl.bind(mainMod .. " + CONTROL + SHIFT + mouse_up",   hl.dsp.window.move({ workspace = "m-1" }))
hl.bind(mainMod .. " + CONTROL + SHIFT + mouse_down", hl.dsp.window.move({ workspace = "m+1" }))
for i = 1, NUM_WPM do
    local key = i % 10
    hl.bind(mainMod .. " + SHIFT + CONTROL + " .. digitCode(key), hl.dsp.window.move({ workspace = "m~" .. i }))
end
-- Move window to a relative workspace without following it. Was SUPER+SHIFT+ALT;
-- with the base layer now ALT, that collapses to ALT+SHIFT, which rice already
-- uses to move a window to an absolute workspace. Re-homed to ALT+SHIFT+CONTROL
-- with no-follow... which is also taken above. Dropped: no spare ALT+SHIFT+digit
-- chord remains. Use the follow version (ALT+SHIFT+digit, rice) instead.

-- Move & Resize with mouse
-- Removed (rice_binds wins): ALT+mouse:272 drag, ALT+mouse:273 resize. rice
-- binds the identical actions.

-- Zoom
local function zoomfunction(value)
    local zoomvalue = hl.get_config("cursor:zoom_factor")
    if (zoomvalue + value) > 3.0 then
        hl.config({ cursor = { zoom_factor = 3.0 } })
    elseif (zoomvalue + value) < 1.0 then
        hl.config({ cursor = { zoom_factor = 1.0 } })
    else
        hl.config({ cursor = { zoom_factor = zoomvalue + value } })
    end
end
-- Removed (rice_binds wins): ALT+Minus zoom-out collided with rice ALT+minus
-- (toggle special workspace); Minus and minus are the same key. Zoom-out stays
-- available on the keypad bind below (code:82).
hl.bind(mainMod .. " + Plus", function() zoomfunction(0.3) end, { repeating = true })

--# Zoom with keypad
hl.bind(mainMod .. " + code:82", function() zoomfunction(-0.3) end, { repeating = true })
hl.bind(mainMod .. " + code:86", function() zoomfunction(0.3) end, { repeating = true })


------------------
---- LAUNCHER ----
------------------

-- Removed (rice_binds wins): ALT+Return terminal (rice has identical), ALT+E
-- file manager (rice togglesplit), ALT+C calculator (rice browser), ALT+W
-- browser (rice group toggle), ALT+L lock (rice focus up).
hl.bind(mainMod .. " + T",          hl.dsp.exec_cmd(launchPrefix .. EDITOR))
hl.bind("XF86Calculator",           hl.dsp.exec_cmd(launchPrefix .. CALCULATOR))
hl.bind("CONTROL + SHIFT + Escape", hl.dsp.exec_cmd(launchPrefix .. TERMINAL .. " -e btop"))
hl.bind(mainMod .. " + Z",          hl.dsp.exec_cmd(noctCall .. "settings-toggle"))
hl.bind(mainMod .. " + X",          hl.dsp.exec_cmd(noctCall .. "panel-toggle control-center"))
hl.bind(mainMod .. " + Space",      hl.dsp.exec_cmd(noctCall .. "panel-toggle launcher"))
hl.bind(mainMod .. " + period",     hl.dsp.exec_cmd(noctCall .. "panel-toggle launcher /emo"))
-- Removed: ALT+C session panel (was SUPER+ALT+C; collapses to ALT+C = rice browser).

---------------------------
---- HARDWARE CONTROLS ----
---------------------------

-- Audio
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd(noctCall .. "volume-up"),   { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd(noctCall .. "volume-down"), { locked = true, repeating = true })
hl.bind("XF86AudioMute",        hl.dsp.exec_cmd(noctCall .. "volume-mute"), { locked = true })
hl.bind("XF86AudioMicMute",     hl.dsp.exec_cmd(noctCall .. "mic-mute"),    { locked = true })

-- Media
hl.bind("XF86AudioPlay",  hl.dsp.exec_cmd(noctCall .. "media toggle"),   { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd(noctCall .. "media toggle"),   { locked = true })
hl.bind("XF86AudioNext",  hl.dsp.exec_cmd(noctCall .. "media next"),     { locked = true })
hl.bind("XF86AudioPrev",  hl.dsp.exec_cmd(noctCall .. "media previous"), { locked = true })

-- Brightness
hl.bind("XF86MonBrightnessUp",   hl.dsp.exec_cmd(noctCall .. "brightness-up"),   { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd(noctCall .. "brightness-down"), { locked = true, repeating = true })

-- Keyboard backlight
hl.bind("XF86KbdBrightnessUp",   hl.dsp.exec_cmd(noctCall .. "keyboard-backlight-up"),     { locked = true, repeating = true })
hl.bind("XF86KbdBrightnessDown", hl.dsp.exec_cmd(noctCall .. "keyboard-backlight-down"),   { locked = true, repeating = true })
hl.bind("XF86KbdLightOnOff",     hl.dsp.exec_cmd(noctCall .. "keyboard-backlight-toggle"), { locked = true })

-------------------
---- UTILITIES ----
-------------------

-- Screen Capture
hl.bind(mainMod .. " + P",     hl.dsp.exec_cmd("hyprpicker -a -n"))
hl.bind("Print",               hl.dsp.exec_cmd(noctCall .. "screenshot-region"))
hl.bind(mainMod .. " + Print", hl.dsp.exec_cmd(noctCall .. "screenshot-fullscreen"))

-- Theming and Wallpaper
hl.bind(mainMod .. " + SHIFT + W", hl.dsp.exec_cmd(noctCall .. "panel-toggle wallpaper"))

-- Clipboard
-- Removed (rice_binds wins): ALT+V clipboard (rice uses ALT+V for togglesplit).

-- Notifications
hl.bind(mainMod .. " + A", hl.dsp.exec_cmd(noctCall .. "panel-toggle control-center notifications"))

-------------------------------
---- WORKSPACES & MONITORS ----
-------------------------------

-- Focus on monitors
-- Removed (rice_binds wins): ALT+<digit> monitor focus. rice binds ALT+<digit>
-- to focus that workspace number.

-- Focus on workspace number
-- Absolute: removed. Was SUPER+ALT+<digit>; collapses to ALT+<digit>, which rice
-- already binds to absolute workspace focus.
-- Relative
for i = 1, NUM_WPM do
    local key = i % 10
    hl.bind(mainMod .. " + CONTROL + " .. digitCode(key), hl.dsp.focus({ workspace = "m~" .. i }))
end

-- Move to adjacent workspaces and next empty on a given monitor
hl.bind(mainMod .. " + CONTROL + Right",       hl.dsp.focus({ workspace = "m+1" }))
hl.bind(mainMod .. " + CONTROL + Left",        hl.dsp.focus({ workspace = "m-1" }))
hl.bind(mainMod .. " + CONTROL + Down",        hl.dsp.focus({ workspace = "emptym" }))

-- Scroll through existing workspaces & monitors
hl.bind(mainMod .. " + mouse_down",           hl.dsp.focus({ workspace = "m-1" }))
hl.bind(mainMod .. " + mouse_up",             hl.dsp.focus({ workspace = "m+1" }))
hl.bind(mainMod .. " + CONTROL + mouse_up",   hl.dsp.focus({ workspace = "m-1" }))
hl.bind(mainMod .. " + CONTROL + mouse_down", hl.dsp.focus({ workspace = "m+1" }))

-- Special workspace (scratchpad)
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.window.move({ workspace = "special" }))
-- Removed (rice_binds wins): ALT+S toggle special (rice uses ALT+S for group toggle;
-- rice toggles special on ALT+minus).
