-- Keeps each Space's candidate window list ready before the switcher asks
-- for it, so opening the overlay draws straight from memory instead of
-- waiting on accessibility round trips (slowest right after idle, when
-- macOS has napped the apps being asked).
--
-- The list is rebuilt in the background whenever something likely changed
-- it - an app launching/quitting/activating/hiding, a Space switch, waking
-- from sleep - plus a slow heartbeat for changes no watcher reports (e.g. a
-- new window opened inside an already-active app). Anything still missed
-- is caught by controller.lua, which revalidates right after drawing.

local sources = require("window_switcher.sources")

local M = {}

-- Bursts of events (an app activating often also unhides it, a Space
-- switch activates another app) collapse into one rebuild after this delay.
local REFRESH_DEBOUNCE = 0.3
local HEARTBEAT_INTERVAL = 45
-- Deferred on config load so a reload (every save, see init.lua) isn't
-- held up by the first sweep.
local PREWARM_DELAY = 0.5

-- spaceId -> sources.list(true, spaceId) result from the latest rebuild.
local bySpace = {}

-- Rebuilds the focused Space's list synchronously and returns it.
function M.refresh()
    local spaceId = hs.spaces.focusedSpace()
    local windows = sources.list(true, spaceId)
    -- Icons are cached per bundle ID in sources.lua; loading them here
    -- keeps that disk read off the first draw too.
    for _, window in ipairs(windows) do
        sources.appIcon(window)
    end
    bySpace[spaceId] = windows
    return windows
end

-- The focused Space's list from the latest rebuild, or nil if it has
-- never been built (e.g. a Space created since the config loaded).
function M.get()
    return bySpace[hs.spaces.focusedSpace()]
end

-- Watchers and timers are kept in locals so they aren't garbage collected
-- (which would silently stop them).
local debounced = hs.timer.delayed.new(REFRESH_DEBOUNCE, M.refresh)

local APP_EVENTS = {
    [hs.application.watcher.launched] = true,
    [hs.application.watcher.terminated] = true,
    [hs.application.watcher.activated] = true,
    [hs.application.watcher.hidden] = true,
    [hs.application.watcher.unhidden] = true,
}
local appWatcher = hs.application.watcher.new(function(_, event)
    if APP_EVENTS[event] then
        debounced:start()
    end
end)

local spaceWatcher = hs.spaces.watcher.new(function()
    debounced:start()
end)

local wakeWatcher = hs.caffeinate.watcher.new(function(event)
    if event == hs.caffeinate.watcher.systemDidWake or event == hs.caffeinate.watcher.screensDidUnlock then
        debounced:start()
    end
end)

local heartbeat = hs.timer.new(HEARTBEAT_INTERVAL, M.refresh)

function M.start()
    appWatcher:start()
    spaceWatcher:start()
    wakeWatcher:start()
    heartbeat:start()
    hs.timer.doAfter(PREWARM_DELAY, M.refresh)
end

return M
