-- Lists candidate windows for the switcher: standard windows on the
-- currently focused Space, optionally including minimized ones.
--
-- Everything comes from a single hs.window.allWindows() sweep. The obvious
-- pairing - visibleWindows() plus minimizedWindows() - walks the
-- accessibility tree twice and measured 2-3x slower per switcher open
-- (~43-72ms vs ~17-21ms), for an identical window list. allWindows()
-- doesn't do visibleWindows()' filtering for us, so the two things it
-- implied are done here explicitly: hidden apps are skipped, and windows
-- are scoped to the focused Space.
--
-- Minimized windows don't show up in hs.window.visibleWindows(), but they
-- do in allWindows(), and they're filtered by Space the same way as the
-- rest.

local M = {}

function M.appName(window)
    return (window:application() and window:application():name()) or "?"
end

function M.label(window)
    return string.format("%s - %s", M.appName(window), window:title() or "")
end

function M.appIcon(window)
    local app = window:application()
    local bundleID = app and app:bundleID()
    return bundleID and hs.image.imageFromAppBundle(bundleID) or nil
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
    -- app:isHidden() is an accessibility round trip, so it's memoized per
    -- app rather than asked once per window of that app.
    local hidden = {}

    for _, w in ipairs(hs.window.allWindows()) do
        -- Space membership first: it's a cheap CoreGraphics lookup, and it
        -- throws out most windows before anything reads accessibility.
        if M.isOnSpace(w, spaceId) then
            local app = w:application()
            local pid = app and app:pid()
            if pid and hidden[pid] == nil then
                hidden[pid] = app:isHidden()
            end

            if not (pid and hidden[pid]) then
                if w:isMinimized() then
                    -- Not filtering by isStandard() here: while minimized,
                    -- a window's AX subrole is unreliably reported (e.g. a
                    -- plain TextEdit document can come back as AXDialog
                    -- instead of AXStandardWindow), so the check used below
                    -- for non-minimized windows would drop legitimate ones.
                    if includeMinimized then
                        table.insert(windows, w)
                    end
                elseif w:isStandard() then
                    table.insert(windows, w)
                end
            end
        end
    end

    table.sort(windows, function(a, b)
        return M.appName(a) < M.appName(b)
    end)

    return windows
end

return M
