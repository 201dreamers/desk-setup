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
-- Both lists always travel together (same shape, same operations), so they
-- live in one table keyed by name instead of four parallel variables - every
-- function that needs "whichever list is active" does one lookup instead of
-- repeating an if/else per list.
local lists = {
    regular = { windows = {}, selectedIndex = 1 },
    minimized = { windows = {}, selectedIndex = 1 },
}
local currentWindowIndex = nil
-- "regular" | "minimized" - which list j/k currently moves the selection in.
local activeList = "regular"
-- Help box is hidden by default; "?" toggles it, reset to hidden on show().
local helpVisible = false

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
    lists.regular.windows, currentWindowIndex = moveCurrentToMiddle(regular, focusedIndex)
    lists.minimized.windows = minimized

    for _, list in pairs(lists) do
        if list.selectedIndex > #list.windows then
            list.selectedIndex = 1
        end
    end
end

local function initialSelectedIndex()
    if not currentWindowIndex then
        return 1
    end
    if START_ON_CURRENT_WINDOW then
        return currentWindowIndex
    end
    return (currentWindowIndex % #lists.regular.windows) + 1
end

local function redraw()
    overlay.draw({
        regularWindows = lists.regular.windows,
        minimizedWindows = lists.minimized.windows,
        activeList = activeList,
        regularSelectedIndex = lists.regular.selectedIndex,
        minimizedSelectedIndex = lists.minimized.selectedIndex,
        currentWindowIndex = currentWindowIndex,
        helpVisible = helpVisible,
    })
end

local function moveSelection(delta)
    local list = lists[activeList]
    if #list.windows == 0 then
        return
    end
    list.selectedIndex = ((list.selectedIndex - 1 + delta) % #list.windows) + 1
    redraw()
end

local function focusSelected()
    local list = lists[activeList]
    local window = list.windows[list.selectedIndex]
    if window then
        if window:isMinimized() then
            window:unminimize()
        end
        window:focus()
    end
    M.hide()
end

-- Clicking anywhere in the overlay acts like pressing return/space.
overlay.onClick(focusSelected)

-- Swaps which list j/k drives. Refuses to switch into an empty list (its
-- column renders nothing, so a highlight with no visible badge would look
-- like a glitch) and says so instead.
function M.toggleActiveList()
    local targetList = activeList == "regular" and "minimized" or "regular"
    if #lists[targetList].windows == 0 then
        overlay.showNotification(targetList == "minimized" and "No minimized windows" or "No regular windows")
        return
    end
    activeList = targetList
    redraw()
    overlay.showNotification(activeList == "regular" and "Selector: regular windows" or "Selector: minimized windows")
end

function M.show()
    refresh()
    if #lists.regular.windows == 0 and #lists.minimized.windows == 0 then
        hs.alert.show("No windows on this Space")
        return
    end
    activeList = #lists.regular.windows > 0 and "regular" or "minimized"
    lists.regular.selectedIndex = initialSelectedIndex()
    helpVisible = false
    redraw()
    modal:enter()
end

function M.hide()
    modal:exit()
    overlay.clear()
end

modal:bind({}, "down", function() moveSelection(1) end)
modal:bind({}, "up", function() moveSelection(-1) end)
modal:bind({}, "j", function() moveSelection(1) end)
modal:bind({}, "k", function() moveSelection(-1) end)
modal:bind({}, "return", focusSelected)
modal:bind({}, "space", focusSelected)
modal:bind({}, "escape", M.hide)
modal:bind({}, "m", M.toggleActiveList)
-- "?" has no direct hs.hotkey key name - it's shift + "/".
modal:bind({ "shift" }, "/", function()
    helpVisible = not helpVisible
    redraw()
end)

return M
