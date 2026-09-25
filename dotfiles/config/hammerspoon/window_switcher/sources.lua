-- Lists candidate windows for the switcher: standard windows on the
-- currently focused Space, optionally including minimized ones.
--
-- Windows are collected app by app rather than through
-- hs.window.allWindows(). allWindows() asks every app with kind() >= 0 for
-- its windows, menu-bar agents and background helpers included - ~140 apps
-- here vs ~19 regular ones, and the agents were ~73% of the sweep's cost
-- while owning no switchable windows. Each app is an accessibility round
-- trip, and an app macOS has napped answers slowly the first time after
-- idle, which is what made the first switcher open feel sluggish. So only
-- regular (Dock) apps are asked, plus the frontmost app whatever its kind,
-- so a focused window of an accessory app (e.g. the Hammerspoon Console
-- with its Dock icon hidden) still shows up. Hidden apps are skipped before
-- they're asked anything.
--
-- The obvious visibleWindows() plus minimizedWindows() pairing walks the
-- same app list twice, so it's no better - minimized windows come from the
-- same per-app query here and are filtered by Space the same way as the
-- rest.

local M = {}

function M.appName(window)
    return (window:application() and window:application():name()) or "?"
end

function M.label(window)
    return string.format("%s - %s", M.appName(window), window:title() or "")
end

-- Icons are loaded from disk per bundle ID, and the overlay asks for them on
-- every redraw (each j/k press), so they're cached for the session.
local iconCache = {}

function M.appIcon(window)
    local app = window:application()
    local bundleID = app and app:bundleID()
    if not bundleID then
        return nil
    end
    if iconCache[bundleID] == nil then
        iconCache[bundleID] = hs.image.imageFromAppBundle(bundleID) or false
    end
    return iconCache[bundleID] or nil
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

-- Regular apps plus the frontmost one (see header), minus hidden ones.
local function candidateApps()
    local frontmost = hs.application.frontmostApplication()
    local frontmostPid = frontmost and frontmost:pid()
    local apps = {}
    for _, app in ipairs(hs.application.runningApplications()) do
        if (app:kind() == 1 or app:pid() == frontmostPid) and not app:isHidden() then
            table.insert(apps, app)
        end
    end
    return apps
end

-- spaceId defaults to the focused Space.
function M.list(includeMinimized, spaceId)
    spaceId = spaceId or hs.spaces.focusedSpace()
    local windows = {}

    for _, app in ipairs(candidateApps()) do
        for _, w in ipairs(app:allWindows()) do
            -- Space membership first: it's a cheap CoreGraphics lookup, and
            -- it throws out most windows before anything reads accessibility.
            if M.isOnSpace(w, spaceId) then
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

    -- Alphabetical by app, then by title within an app, case-insensitive
    -- (plain byte order would put "iTerm" after "Zed"). Keys are read once
    -- up front since each is an accessibility call, and the id breaks ties
    -- so equal names don't swap places (and renumber) between opens.
    local keys = {}
    for _, w in ipairs(windows) do
        keys[w] = { M.appName(w):lower(), (w:title() or ""):lower(), w:id() or 0 }
    end
    table.sort(windows, function(a, b)
        local ka, kb = keys[a], keys[b]
        if ka[1] ~= kb[1] then
            return ka[1] < kb[1]
        end
        if ka[2] ~= kb[2] then
            return ka[2] < kb[2]
        end
        return ka[3] < kb[3]
    end)

    return windows
end

return M
