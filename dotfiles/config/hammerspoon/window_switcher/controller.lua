-- Facade over sources + overlay: owns switcher state (current window list,
-- selection, minimized-toggle) and the modal keymap, exposing the small
-- surface skhd needs (show/hide) plus the actions bound to keys.

local sources = require("window_switcher.sources")
local overlay = require("window_switcher.overlay")

local M = {}

-- true:  opening the switcher highlights the currently active window first,
--        move to another one with tab/j/k.
-- false: opening the switcher jumps straight to the next window (classic
--        alt-tab feel, like macOS's own app switcher).
local START_ON_CURRENT_WINDOW = false

local modal = hs.hotkey.modal.new()
local windows = {}
local selectedIndex = 1
local currentWindowIndex = nil
local includeMinimized = false

local function refresh()
    windows = sources.list(includeMinimized)
    currentWindowIndex = sources.indexOfFocused(windows)
    if selectedIndex > #windows then
        selectedIndex = 1
    end
end

local function initialSelectedIndex()
    if not currentWindowIndex then
        return 1
    end
    if START_ON_CURRENT_WINDOW then
        return currentWindowIndex
    end
    return (currentWindowIndex % #windows) + 1
end

local function redraw()
    overlay.draw(windows, selectedIndex, currentWindowIndex)
end

local function moveSelection(delta)
    if #windows == 0 then
        return
    end
    selectedIndex = ((selectedIndex - 1 + delta) % #windows) + 1
    redraw()
end

local function focusSelected()
    local window = windows[selectedIndex]
    if window then
        if window:isMinimized() then
            window:unminimize()
        end
        window:focus()
    end
    M.hide()
end

function M.toggleMinimized()
    includeMinimized = not includeMinimized
    refresh()
    redraw()
    hs.alert.closeAll()
    hs.alert.show(includeMinimized and "Minimized windows: shown" or "Minimized windows: hidden", 0.6)
end

function M.show()
    refresh()
    if #windows == 0 then
        hs.alert.show("No windows on this Space")
        return
    end
    selectedIndex = initialSelectedIndex()
    redraw()
    modal:enter()
end

function M.hide()
    modal:exit()
    overlay.clear()
end

modal:bind({}, "tab", function() moveSelection(1) end)
modal:bind({ "shift" }, "tab", function() moveSelection(-1) end)
modal:bind({}, "right", function() moveSelection(1) end)
modal:bind({}, "left", function() moveSelection(-1) end)
modal:bind({}, "j", function() moveSelection(1) end)
modal:bind({}, "k", function() moveSelection(-1) end)
modal:bind({}, "m", M.toggleMinimized)
modal:bind({}, "return", focusSelected)
modal:bind({}, "space", focusSelected)
modal:bind({}, "escape", M.hide)

return M
