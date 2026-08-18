-- Lists candidate windows for the switcher: standard windows on the
-- currently focused Space, optionally including minimized ones.
--
-- Minimized windows don't show up in hs.window.visibleWindows(), but they
-- still carry a Space id via hs.spaces.windowSpaces(), so they're filtered
-- the same way as visible windows.

local M = {}

function M.appName(window)
    return (window:application() and window:application():name()) or "?"
end

function M.label(window)
    return string.format("%s — %s", M.appName(window), window:title() or "")
end

function M.isOnSpace(window, spaceId)
    for _, sid in ipairs(hs.spaces.windowSpaces(window) or {}) do
        if sid == spaceId then
            return true
        end
    end
    return false
end

function M.indexOfFocused(windows)
    local focused = hs.window.focusedWindow()
    if not focused then
        return nil
    end
    for i, w in ipairs(windows) do
        if w:id() == focused:id() then
            return i
        end
    end
    return nil
end

function M.list(includeMinimized)
    local spaceId = hs.spaces.focusedSpace()
    local windows = {}

    for _, w in ipairs(hs.window.visibleWindows()) do
        if w:isStandard() then
            table.insert(windows, w)
        end
    end

    if includeMinimized then
        for _, w in ipairs(hs.window.minimizedWindows()) do
            if w:isStandard() and M.isOnSpace(w, spaceId) then
                table.insert(windows, w)
            end
        end
    end

    table.sort(windows, function(a, b)
        return M.appName(a) < M.appName(b)
    end)

    return windows
end

return M
