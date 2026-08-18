-- Draws the switcher overlay: a rectangle traced over each real window's
-- on-screen frame (minimized windows have none, so they get a labeled chip
-- along the bottom instead), plus one centered label for the current
-- selection.
--
-- Only owns rendering - it knows nothing about how the window list or the
-- selection index came to be, so styling can change without touching
-- sources.lua or controller.lua.

local sources = require("window_switcher.sources")

local M = {}

local HIGHLIGHT = { red = 0.20, green = 0.55, blue = 1.0, alpha = 0.9 }
local DIM = { red = 1, green = 1, blue = 1, alpha = 0.35 }
local CURRENT = { white = 0.55, alpha = 0.75 }
local SELECTED_LINE_WIDTH = 6
local DIM_LINE_WIDTH = 1.5
local CURRENT_LINE_WIDTH = 3
local LABEL_FILL = { white = 0.75, alpha = 1 }
local LABEL_TEXT_COLOR = { white = 0.1 }
local CHIP_WIDTH, CHIP_HEIGHT = 200, 36
local CHIP_MARGIN = 10
local LABEL_PADDING_X, LABEL_PADDING_Y = 24, 10
local HELP_WIDTH = 300
local HELP_MARGIN = 20
local HELP_PADDING = 14
local HELP_ROW_GAP = 4
local HELP_ROW_HEIGHT = 20
local HELP_KEY_COLUMN_WIDTH = 135
local HELP_COLUMN_GAP = 8
local HELP_FONT = "Menlo"
local HELP_TEXT_SIZE = 13
local HELP_ROWS = {
    { "tab / j", "next" },
    { "shift-tab / k", "prev" },
    { "m", "toggle minimized" },
    { "return / space", "select" },
    { "esc", "cancel" },
}

local BACKGROUND_FILL = { red = 0.05, green = 0.05, blue = 0.05, alpha = 0.85 }
local BACKGROUND_RADII = { xRadius = 10, yRadius = 10 }
local TEXT_COLOR = { white = 0.82 }

local canvas = nil

function M.clear()
    if canvas then
        canvas:delete()
        canvas = nil
    end
end

local function drawMinimizedChip(chipX, chipY, window, color, lineWidth)
    canvas:appendElements({
        type = "rectangle",
        frame = { x = chipX, y = chipY, w = CHIP_WIDTH, h = CHIP_HEIGHT },
        fillColor = { red = 0.1, green = 0.1, blue = 0.1, alpha = 0.8 },
        strokeColor = color,
        strokeWidth = lineWidth,
        roundedRectRadii = { xRadius = 6, yRadius = 6 },
    })
    canvas:appendElements({
        type = "text",
        frame = { x = chipX + 8, y = chipY + 8, w = CHIP_WIDTH - 16, h = CHIP_HEIGHT - 16 },
        text = sources.label(window) .. "  (minimized)",
        textColor = TEXT_COLOR,
        textSize = 12,
    })
    return chipX + CHIP_WIDTH + CHIP_MARGIN
end

local function drawWindowFrame(screenFrame, window, color, lineWidth)
    local f = window:frame()
    canvas:appendElements({
        type = "rectangle",
        frame = { x = f.x - screenFrame.x, y = f.y - screenFrame.y, w = f.w, h = f.h },
        fillColor = { alpha = 0 },
        strokeColor = color,
        strokeWidth = lineWidth,
        roundedRectRadii = { xRadius = 8, yRadius = 8 },
    })
end

-- Badge is sized to the label text itself (measured via minimumTextSize),
-- not a fixed box, so short names don't float in oversized padding and long
-- names don't clip.
local function drawSelectedLabel(screenFrame, window)
    local styledText = hs.styledtext.new(sources.label(window), {
        font = { size = 15 },
        color = LABEL_TEXT_COLOR,
        paragraphStyle = { alignment = "center" },
    })

    local textSize = canvas:minimumTextSize(styledText)
    local badgeWidth = textSize.w + LABEL_PADDING_X * 2
    local badgeHeight = textSize.h + LABEL_PADDING_Y * 2
    local frame = {
        x = (screenFrame.w - badgeWidth) / 2,
        y = (screenFrame.h - badgeHeight) / 2,
        w = badgeWidth,
        h = badgeHeight,
    }

    canvas:appendElements({
        type = "rectangle",
        frame = frame,
        fillColor = LABEL_FILL,
        strokeColor = { alpha = 0 },
        roundedRectRadii = { xRadius = badgeHeight / 2, yRadius = badgeHeight / 2 },
    })
    canvas:appendElements({
        type = "text",
        frame = {
            x = frame.x,
            y = frame.y + (badgeHeight - textSize.h) / 2,
            w = badgeWidth,
            h = textSize.h,
        },
        text = styledText,
    })
end

-- Key and description are separate text elements side by side, so a long
-- description wraps within its own column instead of bleeding under the key.
-- Row height is a fixed constant (not measured) - simpler and avoids the
-- canvas text-measurement API entirely for five short, static rows.
local function drawHelpRow(x, y, descriptionWidth, key, description)
    canvas:appendElements({
        type = "text",
        frame = { x = x, y = y, w = HELP_KEY_COLUMN_WIDTH - HELP_COLUMN_GAP, h = HELP_ROW_HEIGHT },
        text = hs.styledtext.new(key .. " -", {
            font = { name = HELP_FONT, size = HELP_TEXT_SIZE },
            color = TEXT_COLOR,
            paragraphStyle = { alignment = "right" },
        }),
    })
    canvas:appendElements({
        type = "text",
        frame = { x = x + HELP_KEY_COLUMN_WIDTH, y = y, w = descriptionWidth, h = HELP_ROW_HEIGHT },
        text = hs.styledtext.new(description, {
            font = { name = HELP_FONT, size = HELP_TEXT_SIZE },
            color = TEXT_COLOR,
        }),
    })
end

local function drawHelpBox(screenFrame)
    local boxX = screenFrame.w - HELP_MARGIN - HELP_WIDTH
    local boxY = HELP_MARGIN
    local contentWidth = HELP_WIDTH - (HELP_PADDING * 2)
    local descriptionWidth = contentWidth - HELP_KEY_COLUMN_WIDTH
    local boxHeight = (HELP_PADDING * 2)
        + (#HELP_ROWS * HELP_ROW_HEIGHT)
        + ((#HELP_ROWS - 1) * HELP_ROW_GAP)

    canvas:appendElements({
        type = "rectangle",
        frame = { x = boxX, y = boxY, w = HELP_WIDTH, h = boxHeight },
        fillColor = BACKGROUND_FILL,
        strokeColor = { alpha = 0 },
        roundedRectRadii = BACKGROUND_RADII,
    })

    local rowY = boxY + HELP_PADDING
    for _, row in ipairs(HELP_ROWS) do
        drawHelpRow(boxX + HELP_PADDING, rowY, descriptionWidth, row[1], row[2])
        rowY = rowY + HELP_ROW_HEIGHT + HELP_ROW_GAP
    end
end

function M.draw(windows, selectedIndex, currentIndex)
    M.clear()
    local screenFrame = hs.screen.mainScreen():frame()
    canvas = hs.canvas.new(screenFrame)
    canvas:level(hs.canvas.windowLevels.overlay)
    canvas:behavior(hs.canvas.windowBehaviors.canJoinAllSpaces)

    drawHelpBox(screenFrame)

    local chipX, chipY = 20, screenFrame.h - 60

    for i, window in ipairs(windows) do
        if window:isMinimized() then
            local selected = (i == selectedIndex)
            local color = selected and HIGHLIGHT or DIM
            local lineWidth = selected and SELECTED_LINE_WIDTH or DIM_LINE_WIDTH
            chipX = drawMinimizedChip(chipX, chipY, window, color, lineWidth)
        else
            -- Selected window gets the blue highlight border; the window
            -- that was focused before the switcher opened gets its own
            -- subdued marker instead.
            local selected = (i == selectedIndex)
            local isCurrent = (i == currentIndex)
            local color = selected and HIGHLIGHT or (isCurrent and CURRENT or DIM)
            local lineWidth = selected and SELECTED_LINE_WIDTH or (isCurrent and CURRENT_LINE_WIDTH or DIM_LINE_WIDTH)
            drawWindowFrame(screenFrame, window, color, lineWidth)
        end
    end

    local selectedWindow = windows[selectedIndex]
    if selectedWindow then
        drawSelectedLabel(screenFrame, selectedWindow)
    end

    canvas:show()
end

return M
