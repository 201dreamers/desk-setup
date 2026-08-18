-- Facade over sources + overlay: owns switcher state (the two independent
-- window lists, their selections, which one is active) and the modal
-- keymap, exposing the small surface skhd needs (show/hide) plus the
-- actions bound to keys.
--
-- Minimized windows are always listed (in their own column, via overlay.lua)
-- rather than gated behind a toggle. "m" instead swaps which list j/k
-- drives - selection never crosses between the two lists on its own.

local sources = require("window_switcher.sources")
local overlay = require("window_switcher.overlay")

local M = {}

-- true:  opening the switcher highlights the currently active window first,
--        move to another one with tab/j/k.
-- false: opening the switcher jumps straight to the next window (classic
--        alt-tab feel, like macOS's own app switcher).
local START_ON_CURRENT_WINDOW = true

local modal = hs.hotkey.modal.new()
local regularWindows = {}
local minimizedWindows = {}
local regularSelectedIndex = 1
local minimizedSelectedIndex = 1
local currentWindowIndex = nil
-- "regular" | "minimized" - which list j/k currently moves the selection in.
local activeList = "regular"

-- Reorders list so the currently-focused window sits at the middle index,
-- splitting the rest evenly around it. With an even count there are two
-- middle slots (e.g. 4 windows -> 2 or 3); the smaller one is used, so the
-- current window ends up as the higher of the two (nearer the top of the
-- badge stack) rather than the lower.
local function moveCurrentToMiddle(list, currentIndex)
    if not currentIndex then
        return list, currentIndex
    end

    local current = list[currentIndex]
    local rest = {}
    for i, window in ipairs(list) do
        if i ~= currentIndex then
            table.insert(rest, window)
        end
    end

    local targetIndex = math.ceil(#list / 2)
    local beforeCount = targetIndex - 1

    local reordered = {}
    for i = 1, beforeCount do
        table.insert(reordered, rest[i])
    end
    table.insert(reordered, current)
    for i = beforeCount + 1, #rest do
        table.insert(reordered, rest[i])
    end

    return reordered, targetIndex
end

-- Splits into non-minimized and minimized, preserving each group's
-- relative order, so minimized windows can be appended after everything
-- else regardless of where they'd otherwise sort alphabetically.
local function partitionMinimized(list)
    local regular, minimized = {}, {}
    for _, window in ipairs(list) do
        if window:isMinimized() then
            table.insert(minimized, window)
        else
            table.insert(regular, window)
        end
    end
    return regular, minimized
end

local function refresh()
    local regular, minimized = partitionMinimized(sources.list(true))
    local focusedIndex = sources.indexOfFocused(regular)
    regularWindows, currentWindowIndex = moveCurrentToMiddle(regular, focusedIndex)
    minimizedWindows = minimized

    if regularSelectedIndex > #regularWindows then
        regularSelectedIndex = 1
    end
    if minimizedSelectedIndex > #minimizedWindows then
        minimizedSelectedIndex = 1
    end
end

local function initialSelectedIndex()
    if not currentWindowIndex then
        return 1
    end
    if START_ON_CURRENT_WINDOW then
        return currentWindowIndex
    end
    return (currentWindowIndex % #regularWindows) + 1
end

local function redraw()
    overlay.draw({
        regularWindows = regularWindows,
        minimizedWindows = minimizedWindows,
        activeList = activeList,
        regularSelectedIndex = regularSelectedIndex,
        minimizedSelectedIndex = minimizedSelectedIndex,
        currentWindowIndex = currentWindowIndex,
    })
end

local function moveSelection(delta)
    if activeList == "regular" then
        if #regularWindows == 0 then
            return
        end
        regularSelectedIndex = ((regularSelectedIndex - 1 + delta) % #regularWindows) + 1
    else
        if #minimizedWindows == 0 then
            return
        end
        minimizedSelectedIndex = ((minimizedSelectedIndex - 1 + delta) % #minimizedWindows) + 1
    end
    redraw()
end

local function focusSelected()
    local list = activeList == "regular" and regularWindows or minimizedWindows
    local index = activeList == "regular" and regularSelectedIndex or minimizedSelectedIndex
    local window = list[index]
    if window then
        if window:isMinimized() then
            window:unminimize()
        end
        window:focus()
    end
    M.hide()
end

-- Swaps which list j/k drives. Refuses to switch into an empty list (its
-- column renders nothing, so a highlight with no visible badge would look
-- like a glitch) and says so instead.
function M.toggleActiveList()
    local targetList = activeList == "regular" and "minimized" or "regular"
    local targetCount = targetList == "regular" and #regularWindows or #minimizedWindows
    if targetCount == 0 then
        overlay.showNotification(targetList == "minimized" and "No minimized windows" or "No regular windows")
        return
    end
    activeList = targetList
    redraw()
    overlay.showNotification(activeList == "regular" and "Selector: regular windows" or "Selector: minimized windows")
end

function M.show()
    refresh()
    if #regularWindows == 0 and #minimizedWindows == 0 then
        hs.alert.show("No windows on this Space")
        return
    end
    activeList = #regularWindows > 0 and "regular" or "minimized"
    regularSelectedIndex = initialSelectedIndex()
    redraw()
    modal:enter()
end

function M.hide()
    modal:exit()
    overlay.clear()
end

modal:bind({}, "right", function() moveSelection(1) end)
modal:bind({}, "left", function() moveSelection(-1) end)
modal:bind({}, "j", function() moveSelection(1) end)
modal:bind({}, "k", function() moveSelection(-1) end)
modal:bind({}, "m", M.toggleActiveList)
modal:bind({}, "return", focusSelected)
modal:bind({}, "space", focusSelected)
modal:bind({}, "escape", M.hide)

return M
