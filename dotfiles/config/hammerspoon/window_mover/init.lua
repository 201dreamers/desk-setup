-- Moves the focused window to a specific Space by holding it down (a real
-- titlebar grab) and firing macOS's native "Switch to Desktop N" shortcut
-- (Control+1..9) while it's held - the window rides along with the Space
-- switch, same as it would if you did this by hand.
--
-- Why not yabai's --space, or a real edge-drag: yabai's --space (and
-- Hammerspoon's own hs.spaces window-move calls) hit macOS's private
-- cross-space window API, which is gated behind a SIP partial-disable +
-- scripting-addition install - not set up on this machine (see: `yabai -m
-- window --toggle sticky` also silently no-ops for the same reason - man
-- yabai: "requires SIP to be partially disabled: sticky, pip, shadow,
-- scratchpad"). An earlier version of this script instead simulated a full
-- mouse drag to the screen edge and held it there until Mission Control's
-- edge-switch triggered - that worked, but took ~1.2-1.5s per move (300ms
-- drag-in + up to ~900ms hover before the OS committed) and required
-- machine-specific edge pixel offsets (this Mac's left edge only triggers
-- at x=0 exactly, its right edge needed x=w-1). Grab-and-Control+N instead
-- uses a normal keyboard shortcut for the actual switch, so there's no edge
-- geometry and no hover delay - just however long the Spaces switch
-- animation itself takes (~150-300ms).
--
-- Trigger: skhd sends `ctrl+cmd-1..9` -> `hs -c 'windowMover.moveToSpace(N)'`

local M = {}

-- Time to let the OS register the titlebar grab before the keystroke fires.
local GRAB_SETTLE = 0.03
-- Time to let the Space-switch animation finish before releasing - too
-- short and the window may not have migrated yet when the button lifts.
local SWITCH_SETTLE = 0.3
-- Native "Switch to Desktop N" shortcuts only go up to Control+9.
local MAX_NATIVE_DESKTOP = 9

local function post(eventType, point)
    hs.eventtap.event.newMouseEvent(eventType, point):post()
end

function M.moveToSpace(targetPos)
    local win = hs.window.focusedWindow()
    if not win then
        return
    end

    local screen = win:screen()
    local spaces = hs.spaces.spacesForScreen(screen)
    local activeSpace = hs.spaces.activeSpaceOnScreen(screen)

    if targetPos > MAX_NATIVE_DESKTOP or not spaces[targetPos] or spaces[targetPos] == activeSpace then
        hs.alert.show("No Space " .. targetPos)
        return
    end

    local winFrame = win:frame()
    -- Grab near the top-center of the window (titlebar), away from the
    -- traffic-light buttons that sit at the top-left.
    local grabPoint = hs.geometry.point(winFrame.x + winFrame.w / 2, winFrame.y + 8)
    local types = hs.eventtap.event.types

    post(types.leftMouseDown, grabPoint)
    hs.timer.usleep(GRAB_SETTLE * 1000000)
    hs.eventtap.keyStroke({ "ctrl" }, tostring(targetPos), 0)
    hs.timer.usleep(SWITCH_SETTLE * 1000000)
    post(types.leftMouseUp, grabPoint)

    win:focus()
end

return M
