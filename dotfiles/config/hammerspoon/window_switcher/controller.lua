-- Facade over sources + overlay: owns switcher state (the two independent
-- window lists, their selections, which one is active) and the modal
-- keymap, exposing the small surface skhd needs (show/hide) plus the
-- actions bound to keys.
--
-- Minimized windows are always listed (in their own column, via overlay.lua)
-- rather than gated behind a toggle. "m" instead swaps which list j/k
-- drives - selection never crosses between the two lists on its own.
--
-- Both lists keep sources.lua's alphabetical order, and the first ten
-- windows of the active list are numbered 1-9 then 0 - pressing a digit
-- focuses that window straight away.

local sources = require("window_switcher.sources")
local cache = require("window_switcher.cache")
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
-- Index into lists.regular.windows of the window focused before opening.
local currentWindowIndex = nil
-- "regular" | "minimized" - which list j/k currently moves the selection in.
local activeList = "regular"
-- Help box is hidden by default; "?" toggles it, reset to hidden on show().
local helpVisible = false
-- Bumped on every show()/hide(), so a revalidation queued by one show()
-- can tell the overlay it was meant for is gone (or was reopened).
local generation = 0

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

local function refresh(all)
    local regular, minimized = partitionMinimized(all)
    local focusedIndex = sources.indexOfFocused(regular)
    lists.regular.windows, currentWindowIndex = regular, focusedIndex
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

-- Digit keys 1-9 then 0 map to list positions 1-10 (overlay.lua draws the
-- same numbers on the badges). Positions past the end of the active list do
-- nothing, so a stray digit can't close the switcher.
local function focusNumber(position)
    local list = lists[activeList]
    if position > #list.windows then
        return
    end
    list.selectedIndex = position
    focusSelected()
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

-- A window closed since it was listed can report a nil id; false keeps
-- the table hole-free so sameIds' length check stays reliable.
local function windowIds(list)
    local ids = {}
    for i, window in ipairs(list) do
        ids[i] = window:id() or false
    end
    return ids
end

local function sameIds(a, b)
    if #a ~= #b then
        return false
    end
    for i = 1, #a do
        if a[i] ~= b[i] then
            return false
        end
    end
    return true
end

-- Index of the window with this id in list, or nil.
local function indexOfId(list, id)
    for i, window in ipairs(list) do
        if window:id() == id then
            return i
        end
    end
    return nil
end

-- show() draws from the cached list for instant feedback; this rebuilds it
-- right after, and only redraws if the windows actually changed (one was
-- opened/closed since the last background rebuild). Both lists keep their
-- selection on the same window where it still exists.
local function revalidate(cachedIds)
    local fresh = cache.refresh()
    if sameIds(windowIds(fresh), cachedIds) then
        return
    end

    local selectedIds = {}
    for name, list in pairs(lists) do
        local window = list.windows[list.selectedIndex]
        selectedIds[name] = window and window:id()
    end

    refresh(fresh)
    if #lists.regular.windows == 0 and #lists.minimized.windows == 0 then
        M.hide()
        hs.alert.show("No windows on this Space")
        return
    end
    if #lists[activeList].windows == 0 then
        activeList = activeList == "regular" and "minimized" or "regular"
    end
    for name, list in pairs(lists) do
        list.selectedIndex = (selectedIds[name] and indexOfId(list.windows, selectedIds[name]))
            or (name == "regular" and initialSelectedIndex())
            or 1
    end
    redraw()
end

function M.show()
    generation = generation + 1
    local cached = cache.get()
    -- An empty cached list may just be stale, so it gets a real rebuild
    -- instead of an instant "No windows" alert.
    local fromCache = cached ~= nil and #cached > 0
    refresh(fromCache and cached or cache.refresh())
    if #lists.regular.windows == 0 and #lists.minimized.windows == 0 then
        hs.alert.show("No windows on this Space")
        return
    end
    activeList = #lists.regular.windows > 0 and "regular" or "minimized"
    lists.regular.selectedIndex = initialSelectedIndex()
    helpVisible = false
    redraw()
    modal:enter()

    if fromCache then
        local cachedIds = windowIds(cached)
        local shownGeneration = generation
        -- doAfter(0) runs on the next run loop pass, after the overlay above
        -- has been put on screen, so the rebuild never delays first paint.
        hs.timer.doAfter(0, function()
            if generation == shownGeneration then
                revalidate(cachedIds)
            end
        end)
    end
end

function M.hide()
    generation = generation + 1
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
for position = 1, 10 do
    modal:bind({}, tostring(position % 10), function() focusNumber(position) end)
end
-- "?" has no direct hs.hotkey key name - it's shift + "/".
modal:bind({ "shift" }, "/", function()
    helpVisible = not helpVisible
    redraw()
end)

-- Prewarm on (re)load: build the first window list and the overlay canvas
-- now, so the first open doesn't pay for loading extensions, waking apps'
-- accessibility, or creating the canvas.
cache.start()
overlay.prewarm()

return M
