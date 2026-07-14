-- ~/.hammerspoon/init.lua
-- Per-monitor Sway-style workspaces on macOS (SIP fully enabled).
-- Semantics from the Sway/i3 rice (github.com/mosschief/rice):
--
--   Alt+N        -> switch to Space N on the monitor under the cursor,
--                   creating it first if it doesn't exist (Sway's implicit
--                   "workspace number N").
--   Alt+Shift+N  -> move the focused window to Space N on the window's
--                   monitor, creating it if needed. Focus follows the window
--                   (equivalent to Sway "move container to workspace N;
--                   workspace N").
--
-- Alt matches the Sway bindings, and Karabiner swaps Ctrl<->Cmd in GUI apps
-- but leaves Alt untouched, so Alt+Number is consistent everywhere.
--
-- MECHANISMS (what survived testing on macOS 15.7 / Hammerspoon 1.1.1):
--   * Switching: hs.spaces.gotoSpace() — Mission Control automation. Brief MC
--     flash, but reliable, incl. empty desktops and external displays.
--     (iss-cli's synthetic swipe gestures proved flaky on this machine and
--     are no longer used.)
--   * Moving windows: hs.spaces.moveWindowToSpace() silently no-ops on
--     Sequoia (HS issue #3698), and yabai needs SIP off for it. Instead we
--     synthetically hold the window's titlebar and post the NATIVE
--     Ctrl+(Fn)+Arrow space-switch — macOS carries a held window across
--     spaces. Requires "Move left/right a space" enabled in System Settings >
--     Keyboard > Shortcuts > Mission Control (symbolic hotkeys 79/81 — done
--     via defaults on 2026-07-14). The `fn` flag is REQUIRED: hardware arrow
--     keys carry it and the shortcut matcher won't fire without it.
--   * Space creation: hs.spaces.addSpaceToScreen() — works with SIP enabled.

require("hs.ipc") -- enables the `hs` console CLI (handy for debugging)

-- macOS number-row keycodes are not sequential; map them to Space index.
-- 1..9 then 0 -> Space 10 (matches Sway Alt+0 = workspace 10).
local keyMap = {
  [18] = 1, [19] = 2, [20] = 3, [21] = 4,
  [23] = 5, [22] = 6, [26] = 7, [28] = 8,
  [25] = 9, [29] = 10,
}

-- Serialize operations: a keypress mid-flight would corrupt a drag or leave
-- Mission Control in a weird state.
local busy = false
local function log(fmt, ...) print(string.format("[spaces] " .. fmt, ...)) end

-- 1-based index of the active space on `screen`, plus the space id list.
local function currentSpaceIndex(screen)
  local spaces = hs.spaces.spacesForScreen(screen) or {}
  local active = hs.spaces.activeSpaceOnScreen(screen)
  for i, sid in ipairs(spaces) do
    if sid == active then return i, spaces end
  end
  return nil, spaces
end

-- Ensure the screen has at least n Spaces; calls done() once settled.
local function ensureSpaces(screen, n, done)
  local spaces = hs.spaces.spacesForScreen(screen) or {}
  local missing = n - #spaces
  if missing <= 0 then done() return end
  log("creating %d space(s) on %s", missing, screen:name())
  for _ = 1, missing do
    hs.spaces.addSpaceToScreen(screen, false)
  end
  hs.spaces.closeMissionControl()
  -- let Mission Control close and the space list settle before continuing
  hs.timer.doAfter(0.5, done)
end

-- Alt+N: switch the display under the cursor to its Nth space.
local function gotoSpaceIndex(n)
  local screen = hs.mouse.getCurrentScreen()
  ensureSpaces(screen, n, function()
    local cur, spaces = currentSpaceIndex(screen)
    local target = spaces[n]
    if not target then
      log("no space %d on %s", n, screen:name())
      busy = false
      return
    end
    if cur == n then busy = false return end
    log("switch %s -> space %d (id %d)", screen:name(), n, target)
    local ok, err = hs.spaces.gotoSpace(target)
    if not ok then log("gotoSpace failed: %s", tostring(err)) end
    busy = false
  end)
end

-- Post the native "move left/right a space" shortcut. The fn flag is
-- required — hardware arrow keys carry it and the system shortcut matcher
-- won't recognize the combo without it.
local function postCtrlArrow(dir)
  local ev = hs.eventtap.event
  ev.newKeyEvent({ "ctrl", "fn" }, dir, true):post()
  hs.timer.usleep(80000)
  ev.newKeyEvent({ "ctrl", "fn" }, dir, false):post()
end

-- Alt+Shift+N: move the focused window to space N on ITS display by holding
-- its titlebar while the native shortcut switches the space underneath.
local function moveWindowToSpaceIndex(n)
  local win = hs.window.focusedWindow()
  if not win then
    hs.alert.show("No focused window")
    busy = false
    return
  end
  local screen = win:screen()
  ensureSpaces(screen, n, function()
    local cur = currentSpaceIndex(screen)
    if not cur then
      log("cannot determine active space on %s", screen:name())
      busy = false
      return
    end
    if cur == n then busy = false return end
    local dir = cur < n and "right" or "left"
    local count = math.abs(n - cur)

    local f = win:frame()
    local grab = { x = f.x + f.w / 2, y = f.y + 5 } -- titlebar center
    local origPos = hs.mouse.absolutePosition()
    log("move '%s': space %d -> %d on %s", win:title() or "?", cur, n, screen:name())

    local ev = hs.eventtap.event
    ev.newMouseEvent(ev.types.leftMouseDown, grab):post()

    -- a real drag session needs several dragged events past the drag threshold
    local nudges, i = { 8, 16, 24, 32, 40 }, 0
    local dragT
    dragT = hs.timer.doEvery(0.04, function()
      i = i + 1
      if i <= #nudges then
        ev.newMouseEvent(ev.types.leftMouseDragged,
          { x = grab.x + nudges[i], y = grab.y }):post()
        return
      end
      dragT:stop()
      -- window is now held; step through spaces with the native shortcut
      local stepsDone = 0
      local stepT
      stepT = hs.timer.doEvery(0.55, function()
        stepsDone = stepsDone + 1
        postCtrlArrow(dir)
        if stepsDone >= count then
          stepT:stop()
          -- wait out the last slide animation, then release
          hs.timer.doAfter(0.6, function()
            ev.newMouseEvent(ev.types.leftMouseUp,
              { x = grab.x + nudges[#nudges], y = grab.y }):post()
            hs.mouse.absolutePosition(origPos)
            busy = false
          end)
        end
      end)
    end)
  end)
end

local types = hs.eventtap.event.types

-- NB: globals (not `local`) so they aren't garbage-collected.
spaceSwitcher = hs.eventtap.new(
  { types.keyDown },
  function(event)
    -- macOS silently disables event taps that time out; re-arm if it happens.
    local t = event:getType()
    if t == types.tapDisabledByTimeout or t == types.tapDisabledByUserInput then
      spaceSwitcher:start()
      return false
    end

    local flags = event:getFlags()
    if not flags.alt or flags.cmd or flags.ctrl then return false end

    local num = keyMap[event:getKeyCode()]
    if not num then return false end -- other Alt combos fall through to skhd

    if busy then return true end -- swallow keypresses while an op is in flight
    busy = true
    -- Safety valve: never stay wedged if a callback is lost.
    hs.timer.doAfter(6, function() busy = false end)

    -- Defer real work so the tap callback returns instantly (a slow callback
    -- is what gets taps disabled in the first place).
    if flags.shift then
      hs.timer.doAfter(0, function() moveWindowToSpaceIndex(num) end)
    else
      hs.timer.doAfter(0, function() gotoSpaceIndex(num) end)
    end
    return true -- consume the keystroke
  end
)
spaceSwitcher:start()

-- Watchdog: belt-and-braces re-enable in case the tap dies outside a callback.
tapWatchdog = hs.timer.doEvery(15, function()
  if not spaceSwitcher:isEnabled() then spaceSwitcher:start() end
end)

hs.alert.show("Hammerspoon: Alt+1..0 spaces / Alt+Shift+1..0 move window")
