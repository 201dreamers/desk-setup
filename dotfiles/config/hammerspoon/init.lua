-- Visual keyboard window switcher, scoped to the current Space.
--
-- Trigger: skhd sends `alt - tab` -> `hs -c 'windowSwitcher.show()'` (see skhdrc).
-- Once the overlay is open (release alt, Hammerspoon owns the keys):
--   tab / right / j   -> next window
--   shift-tab / left / k -> previous window
--   m                 -> toggle whether minimized windows are included
--   return            -> focus selected window (unminimizing it first if needed)
--   escape            -> cancel

local windowSwitcher = {}

local overlayCanvas = nil
local modal = hs.hotkey.modal.new()
local windows = {}
local selectedIndex = 1
local includeMinimized = false

local HIGHLIGHT = { red = 0.20, green = 0.55, blue = 1.0, alpha = 0.9 }
local DIM = { red = 1, green = 1, blue = 1, alpha = 0.35 }

-- Windows on the currently focused Space only. Minimized windows don't show up
-- in hs.window.visibleWindows(), but they still carry a Space id via
-- hs.spaces.windowSpaces(), so we can filter them the same way.
local function currentSpaceWindows()
    local spaceId = hs.spaces.focusedSpace()
    local list = {}

    for _, w in ipairs(hs.window.visibleWindows()) do
        if w:isStandard() then
            table.insert(list, w)
        end
    end

    if includeMinimized then
        for _, w in ipairs(hs.window.minimizedWindows()) do
            if w:isStandard() then
                for _, sid in ipairs(hs.spaces.windowSpaces(w) or {}) do
                    if sid == spaceId then
                        table.insert(list, w)
                        break
                    end
                end
            end
        end
    end

    table.sort(list, function(a, b)
        local nameA = a:application() and a:application():name() or ""
        local nameB = b:application() and b:application():name() or ""
        return nameA < nameB
    end)

    return list
end

local function clearOverlay()
    if overlayCanvas then
        overlayCanvas:delete()
        overlayCanvas = nil
    end
end

-- Real (non-minimized) windows get a rectangle traced over their actual frame.
-- Minimized windows have no on-screen frame, so they get a labeled chip along
-- the bottom of the screen instead.
local function drawOverlay()
    clearOverlay()
    local screenFrame = hs.screen.mainScreen():frame()
    overlayCanvas = hs.canvas.new(screenFrame)
    overlayCanvas:level(hs.canvas.windowLevels.overlay)
    overlayCanvas:behavior(hs.canvas.windowBehaviors.canJoinAllSpaces)

    local chipX = 20
    local chipY = screenFrame.h - 60

    for i, w in ipairs(windows) do
        local selected = (i == selectedIndex)
        local color = selected and HIGHLIGHT or DIM
        local lineWidth = selected and 4 or 1.5
        local label = string.format(
            "%s — %s",
            (w:application() and w:application():name()) or "?",
            w:title() or ""
        )

        if w:isMinimized() then
            local chipW, chipH = 200, 36
            overlayCanvas:appendElements({
                type = "rectangle",
                frame = { x = chipX, y = chipY, w = chipW, h = chipH },
                fillColor = { red = 0.1, green = 0.1, blue = 0.1, alpha = 0.8 },
                strokeColor = color,
                strokeWidth = lineWidth,
                roundedRectRadii = { xRadius = 6, yRadius = 6 },
            })
            overlayCanvas:appendElements({
                type = "text",
                frame = { x = chipX + 8, y = chipY + 8, w = chipW - 16, h = chipH - 16 },
                text = label .. "  (minimized)",
                textColor = { white = 1 },
                textSize = 12,
            })
            chipX = chipX + chipW + 10
        else
            local f = w:frame()
            local rel = { x = f.x - screenFrame.x, y = f.y - screenFrame.y, w = f.w, h = f.h }
            overlayCanvas:appendElements({
                type = "rectangle",
                frame = rel,
                fillColor = { alpha = 0 },
                strokeColor = color,
                strokeWidth = lineWidth,
                roundedRectRadii = { xRadius = 8, yRadius = 8 },
            })
            if selected then
                overlayCanvas:appendElements({
                    type = "text",
                    frame = { x = rel.x + 8, y = rel.y + 8, w = rel.w - 16, h = 24 },
                    text = label,
                    textColor = HIGHLIGHT,
                    textSize = 14,
                })
            end
        end
    end

    overlayCanvas:show()
end

local function refreshWindows()
    windows = currentSpaceWindows()
    if selectedIndex > #windows then
        selectedIndex = 1
    end
end

local function moveSelection(delta)
    if #windows == 0 then
        return
    end
    selectedIndex = ((selectedIndex - 1 + delta) % #windows) + 1
    drawOverlay()
end

local function focusSelected()
    local w = windows[selectedIndex]
    if not w then
        windowSwitcher.hide()
        return
    end
    if w:isMinimized() then
        w:unminimize()
    end
    w:focus()
    windowSwitcher.hide()
end

function windowSwitcher.toggleMinimized()
    includeMinimized = not includeMinimized
    refreshWindows()
    drawOverlay()
    hs.alert.closeAll()
    hs.alert.show(includeMinimized and "Minimized windows: shown" or "Minimized windows: hidden", 0.6)
end

function windowSwitcher.show()
    refreshWindows()
    if #windows == 0 then
        hs.alert.show("No windows on this Space")
        return
    end
    selectedIndex = 1
    drawOverlay()
    modal:enter()
end

function windowSwitcher.hide()
    modal:exit()
    clearOverlay()
end

modal:bind({}, "tab", function() moveSelection(1) end)
modal:bind({ "shift" }, "tab", function() moveSelection(-1) end)
modal:bind({}, "right", function() moveSelection(1) end)
modal:bind({}, "left", function() moveSelection(-1) end)
modal:bind({}, "j", function() moveSelection(1) end)
modal:bind({}, "k", function() moveSelection(-1) end)
modal:bind({}, "m", windowSwitcher.toggleMinimized)
modal:bind({}, "return", focusSelected)
modal:bind({}, "escape", windowSwitcher.hide)

-- Exposed as a global so `hs -c 'windowSwitcher.show()'` (invoked from skhd) can reach it.
_G.windowSwitcher = windowSwitcher

return windowSwitcher
