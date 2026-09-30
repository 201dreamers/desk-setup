-- Facade over sources + overlay: owns switcher state (the two window lists
-- and the selection) and the keymap, exposing the small surface skhd needs
-- (show/hide) plus the actions bound to keys.
--
-- Minimized windows are always listed (in their own column, via overlay.lua)
-- but never selected: j/k and the arrows only move through regular windows.
-- A minimized window is opened by its number or by clicking its badge.
--
-- Both lists keep sources.lua's alphabetical order. Jump numbers run across
-- both - regular windows first, then minimized ones - and the first
-- MAX_JUMP_POSITIONS get one: positions 1-10 are keys 1-9 then 0, and
-- 11-20 are "a" followed by 1-9 then 0 (see jumpLabel, which overlay.lua
-- draws on the badges).

local sources = require("window_switcher.sources")
local cache = require("window_switcher.cache")
local overlay = require("window_switcher.overlay")

local M = {}

-- true:  opening the switcher highlights the currently active window first,
--        move to another one with tab/j/k.
-- false: opening the switcher jumps straight to the next window (classic
--        alt-tab feel, like macOS's own app switcher).
local START_ON_CURRENT_WINDOW = false

-- Keys past the tenth window need a prefix: "a" then a digit.
local JUMP_PREFIX = "a"
local MAX_JUMP_POSITIONS = 20

-- Keyboard is grabbed with an eventtap rather than an hs.hotkey.modal: a
-- modal only captures the keys bound in it, so any other key pressed while
-- the switcher is open would still reach the previously focused window.
-- The tap swallows every key event while open and dispatches them itself.
local keyTap = nil
local regularWindows = {}
local minimizedWindows = {}
-- Index into regularWindows of the highlighted window.
local selectedIndex = 1
-- Index into regularWindows of the window focused before opening.
local currentWindowIndex = nil
-- True after "a" was pressed, until the next key: that key's digit then
-- means positions 11-20 instead of 1-10.
local prefixPending = false
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
    regularWindows, minimizedWindows = partitionMinimized(all)
    currentWindowIndex = sources.indexOfFocused(regularWindows)
    if selectedIndex > #regularWindows then
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
    return (currentWindowIndex % #regularWindows) + 1
end

-- Key sequence that jumps to a position: "1"-"9", "0" for the first ten,
-- then "a1"-"a9", "a0" for the next ten; nil past MAX_JUMP_POSITIONS.
local function jumpLabel(position)
    if position > MAX_JUMP_POSITIONS then
        return nil
    end
    local prefix = position > 10 and JUMP_PREFIX or ""
    return prefix .. tostring(position % 10)
end

local function redraw()
    overlay.draw({
        regularWindows = regularWindows,
        minimizedWindows = minimizedWindows,
        selectedIndex = selectedIndex,
        currentWindowIndex = currentWindowIndex,
        jumpLabel = jumpLabel,
        helpVisible = helpVisible,
    })
end

local function moveSelection(delta)
    if #regularWindows == 0 then
        return
    end
    selectedIndex = ((selectedIndex - 1 + delta) % #regularWindows) + 1
    redraw()
end

local function focusWindow(window)
    if window then
        if window:isMinimized() then
            window:unminimize()
        end
        window:focus()
    end
    M.hide()
end

local function focusSelected()
    focusWindow(regularWindows[selectedIndex])
end

-- Window at jump position `position` (regular windows first, then
-- minimized), or nil past the end of both lists.
local function windowAtPosition(position)
    if position <= #regularWindows then
        return regularWindows[position]
    end
    return minimizedWindows[position - #regularWindows]
end

-- Positions past the end of both lists do nothing, so a stray digit can't
-- close the switcher.
local function focusNumber(position)
    local window = windowAtPosition(position)
    if window then
        focusWindow(window)
    end
end

-- Clicking a badge opens that exact window; clicking anywhere else in the
-- overlay acts like pressing return/space.
overlay.onClick(function(target)
    if not target then
        focusSelected()
    elseif target.list == "regular" then
        focusWindow(regularWindows[target.index])
    else
        focusWindow(minimizedWindows[target.index])
    end
end)

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
-- opened/closed since the last background rebuild). The selection stays on
-- the same window where it still exists.
local function revalidate(cachedIds)
    local fresh = cache.refresh()
    if sameIds(windowIds(fresh), cachedIds) then
        return
    end

    local selected = regularWindows[selectedIndex]
    local selectedId = selected and selected:id()

    refresh(fresh)
    if #regularWindows == 0 and #minimizedWindows == 0 then
        M.hide()
        hs.alert.show("No windows on this Space")
        return
    end
    selectedIndex = (selectedId and indexOfId(regularWindows, selectedId)) or initialSelectedIndex()
    redraw()
end

function M.show()
    generation = generation + 1
    local cached = cache.get()
    -- An empty cached list may just be stale, so it gets a real rebuild
    -- instead of an instant "No windows" alert.
    local fromCache = cached ~= nil and #cached > 0
    refresh(fromCache and cached or cache.refresh())
    if #regularWindows == 0 and #minimizedWindows == 0 then
        hs.alert.show("No windows on this Space")
        return
    end
    selectedIndex = initialSelectedIndex()
    prefixPending = false
    helpVisible = false
    redraw()
    keyTap:start()

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
    keyTap:stop()
    overlay.clear()
end

local function toggleHelp()
    helpVisible = not helpVisible
    redraw()
end

-- Key name (as hs.keycodes.map reports it) -> action. Keys that need shift
-- ("?", shift-tab), digits and the "a" prefix are resolved in actionFor
-- before this lookup.
local actions = {
    down = function() moveSelection(1) end,
    up = function() moveSelection(-1) end,
    j = function() moveSelection(1) end,
    k = function() moveSelection(-1) end,
    tab = function() moveSelection(1) end,
    ["return"] = focusSelected,
    space = focusSelected,
    escape = M.hide,
}

-- "1".."9" -> 1..9, "0" -> 10, anything else -> nil.
local function digitPosition(key)
    if not key or not key:match("^%d$") then
        return nil
    end
    local digit = tonumber(key)
    return digit == 0 and 10 or digit
end

-- Returns the action for this key press, or nil to ignore it.
local function actionFor(key, shift)
    local position = (not shift) and digitPosition(key) or nil
    if prefixPending then
        prefixPending = false
        if position then
            return function() focusNumber(position + 10) end
        end
        -- Any other key cancels the prefix and then acts as usual.
    end
    if position then
        return function() focusNumber(position) end
    end
    if not shift and key == JUMP_PREFIX then
        prefixPending = #regularWindows + #minimizedWindows > 10
        if prefixPending then
            return function() overlay.showNotification(JUMP_PREFIX .. " …") end
        end
        return nil
    end
    if shift and key == "tab" then
        return function() moveSelection(-1) end
    end
    if shift and key == "/" then
        -- "?" is shift + "/".
        return toggleHelp
    end
    if not shift then
        return actions[key]
    end
    return nil
end

local function handleKey(event)
    local action = actionFor(hs.keycodes.map[event:getKeyCode()], event:getFlags().shift)
    if action then
        -- Run outside the tap callback: focusing a window can block on a
        -- slow app, and macOS disables a tap whose callback stalls.
        hs.timer.doAfter(0, action)
    end
end

keyTap = hs.eventtap.new({ hs.eventtap.event.types.keyDown, hs.eventtap.event.types.keyUp }, function(event)
    if event:getType() == hs.eventtap.event.types.keyDown then
        handleKey(event)
    end
    -- Swallow everything (keyUp too, and unmapped keys) so nothing reaches
    -- the window underneath while the switcher is open.
    return true
end)

-- Prewarm on (re)load: build the first window list and the overlay canvas
-- now, so the first open doesn't pay for loading extensions, waking apps'
-- accessibility, or creating the canvas.
cache.start()
overlay.prewarm()

return M
