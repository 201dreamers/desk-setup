-- Draws the switcher overlay: a rectangle traced over each real window's
-- on-screen frame (minimized windows have none, so they're skipped here),
-- two independent vertically-scrollable badge columns - regular windows
-- top-left, minimized windows bottom-left in a darker chip-style color,
-- both always visible - with the current selection marked by a blue
-- border in whichever column is currently active, and a help box in the
-- bottom-right corner.
--
-- Only owns rendering - it knows nothing about how the window lists or the
-- selection indices came to be, so styling can change without touching
-- sources.lua or controller.lua.

local sources = require("window_switcher.sources")
local style = require("window_switcher.style")

local M = {}

local canvas = nil
local notificationCanvas = nil

function M.clear()
    if canvas then
        canvas:delete()
        canvas = nil
    end
end

-- Toast notification (e.g. "Minimized windows: shown"), drawn as its own
-- small canvas styled exactly like a minimized-window chip - hs.alert's
-- built-in box has no height control, so it never quite matched.
function M.showNotification(text)
    if notificationCanvas then
        notificationCanvas:delete()
        notificationCanvas = nil
    end

    local screenFrame = hs.screen.mainScreen():frame()
    local measureCanvas = hs.canvas.new(screenFrame)
    local styledText = hs.styledtext.new(text, {
        font = style.BADGE_FONT,
        color = style.TEXT_COLOR,
        paragraphStyle = { alignment = "center" },
    })
    local textSize = measureCanvas:minimumTextSize(styledText)
    measureCanvas:delete()

    local width = textSize.w + style.STRIP_PADDING_X * 2
    local frame = {
        x = screenFrame.x + (screenFrame.w - width) / 2,
        y = screenFrame.y + style.NOTIFICATION_TOP_MARGIN,
        w = width,
        h = style.CHIP_HEIGHT,
    }

    notificationCanvas = hs.canvas.new(frame)
    notificationCanvas:level(hs.canvas.windowLevels.overlay)
    notificationCanvas:behavior(hs.canvas.windowBehaviors.canJoinAllSpaces)
    notificationCanvas:appendElements({
        type = "rectangle",
        frame = { x = 0, y = 0, w = width, h = style.CHIP_HEIGHT },
        fillColor = style.CHIP_FILL,
        strokeColor = { alpha = 0 },
        roundedRectRadii = { xRadius = style.CHIP_HEIGHT / 2, yRadius = style.CHIP_HEIGHT / 2 },
    })
    notificationCanvas:appendElements({
        type = "text",
        frame = { x = 0, y = (style.CHIP_HEIGHT - textSize.h) / 2, w = width, h = textSize.h },
        text = styledText,
    })
    notificationCanvas:show()

    local shown = notificationCanvas
    hs.timer.doAfter(style.NOTIFICATION_DURATION, function()
        if notificationCanvas == shown then
            notificationCanvas:delete()
            notificationCanvas = nil
        end
    end)
end

local function drawWindowFrame(screenFrame, window, color, lineWidth, outlined)
    local f = window:frame()
    local frame = { x = f.x - screenFrame.x, y = f.y - screenFrame.y, w = f.w, h = f.h }
    local radii = { xRadius = 8, yRadius = 8 }

    if outlined and style.OUTLINE_ENABLED then
        canvas:appendElements({
            type = "rectangle",
            frame = frame,
            fillColor = { alpha = 0 },
            strokeColor = style.OUTLINE_COLOR,
            strokeWidth = lineWidth + style.OUTLINE_EXTRA_WIDTH,
            roundedRectRadii = radii,
        })
    end

    canvas:appendElements({
        type = "rectangle",
        frame = frame,
        fillColor = { alpha = 0 },
        strokeColor = color,
        strokeWidth = lineWidth,
        roundedRectRadii = radii,
    })
end

-- utf8-safe substring by character index (inclusive), since window titles
-- can contain multi-byte characters that string.sub would split mid-byte.
local function subChars(text, from, to)
    local len = utf8.len(text)
    if not len then
        return text
    end
    from = math.max(from, 1)
    to = math.min(to, len)
    if from > to then
        return ""
    end
    local startByte = utf8.offset(text, from)
    local endByte = (to < len) and (utf8.offset(text, to + 1) - 1) or #text
    return text:sub(startByte, endByte)
end

-- Shrinks from both ends toward the middle (keeping the longer side one
-- character longer when the length is odd) until the ellipsized text fits
-- maxWidth, so long window names degrade instead of overflowing a badge.
local function truncateMiddle(text, textStyle, maxWidth)
    if canvas:minimumTextSize(hs.styledtext.new(text, textStyle)).w <= maxWidth then
        return text
    end

    local len = utf8.len(text) or #text
    local left = math.ceil(len / 2)
    local right = len - left
    while left > 0 or right > 0 do
        local candidate = subChars(text, 1, left) .. style.ELLIPSIS .. subChars(text, len - right + 1, len)
        if canvas:minimumTextSize(hs.styledtext.new(candidate, textStyle)).w <= maxWidth then
            return candidate
        end
        if left >= right then
            left = left - 1
        else
            right = right - 1
        end
    end
    return style.ELLIPSIS
end

local STRIP_FONT = style.BADGE_FONT
local STRIP_MEASURE_STYLE = { font = STRIP_FONT }

-- One entry per window in a single column (a column is always all-regular
-- or all-minimized, never mixed): measured pill size plus everything
-- needed to draw it, computed once so layout (which badges fit) and
-- drawing (the actual appendElements calls) don't measure text twice.
-- maxLabelWidth scales with screen width instead of a fixed pixel cap, so
-- badges only truncate when a title is genuinely long relative to the
-- display.
local function buildBadges(windows, maxLabelWidth)
    local badges = {}
    for i, window in ipairs(windows) do
        local label = truncateMiddle(sources.label(window), STRIP_MEASURE_STYLE, maxLabelWidth)
        local textSize = canvas:minimumTextSize(hs.styledtext.new(label, STRIP_MEASURE_STYLE))
        local icon = sources.appIcon(window)
        local iconSpace = icon and (style.STRIP_ICON_SIZE + style.STRIP_ICON_GAP) or 0
        table.insert(badges, {
            originalIndex = i,
            label = label,
            icon = icon,
            iconSpace = iconSpace,
            textSize = textSize,
            width = textSize.w + iconSpace + style.STRIP_PADDING_X * 2,
        })
    end
    return badges
end

-- The anchor badge is always kept; neighbors are added alternating
-- below/above (closest first) until the next row would overflow the height
-- budget, so the stack "scrolls" by re-centering on the anchor instead of
-- ever clipping the badge that matters. Every row is the same height, so
-- the budget is just a row count.
local function visibleBadgeRange(count, anchorPos, maxHeight)
    local left, right = anchorPos, anchorPos
    local rowSize = style.STRIP_HEIGHT + style.STRIP_GAP
    local total = style.STRIP_HEIGHT
    while true do
        local addedRight = false
        if right < count then
            local candidate = total + rowSize
            if candidate <= maxHeight then
                total = candidate
                right = right + 1
                addedRight = true
            end
        end
        local addedLeft = false
        if left > 1 then
            local candidate = total + rowSize
            if candidate <= maxHeight then
                total = candidate
                left = left - 1
                addedLeft = true
            end
        end
        if not addedRight and not addedLeft then
            break
        end
    end
    return left, right
end

-- Vertical, left-aligned stack of pill badges, one per window in `windows`.
-- Grows downward from (x, anchorY) when anchoredToTop is true (the regular
-- list, top-left), or upward with its bottom edge pinned to anchorY when
-- false (the minimized list, bottom-left). selectedIndex highlights one
-- badge with a blue border; pass nil to render the whole column with
-- nothing highlighted (the list that isn't currently active for j/k).
local function drawBadgeColumn(screenFrame, windows, selectedIndex, x, anchorY, anchoredToTop, maxHeight, fill, textColor)
    local maxLabelWidth = screenFrame.w * style.STRIP_MAX_LABEL_WIDTH_RATIO
    local badges = buildBadges(windows, maxLabelWidth)
    if #badges == 0 then
        return
    end

    local selectedPos = nil
    for i, badge in ipairs(badges) do
        if badge.originalIndex == selectedIndex then
            selectedPos = i
            break
        end
    end

    local first, last = visibleBadgeRange(#badges, selectedPos or 1, maxHeight)

    local y
    if anchoredToTop then
        y = anchorY
    else
        local rows = last - first + 1
        local totalHeight = rows * style.STRIP_HEIGHT + (rows - 1) * style.STRIP_GAP
        y = anchorY - totalHeight
    end

    for i = first, last do
        local badge = badges[i]
        local selected = (i == selectedPos)
        local badgeRadii = { xRadius = style.STRIP_HEIGHT / 2, yRadius = style.STRIP_HEIGHT / 2 }

        if selected and style.OUTLINE_ENABLED then
            canvas:appendElements({
                type = "rectangle",
                frame = { x = x, y = y, w = badge.width, h = style.STRIP_HEIGHT },
                fillColor = { alpha = 0 },
                strokeColor = style.OUTLINE_COLOR,
                strokeWidth = style.STRIP_SELECTED_BORDER_WIDTH + style.OUTLINE_EXTRA_WIDTH,
                roundedRectRadii = badgeRadii,
            })
        end

        canvas:appendElements({
            type = "rectangle",
            frame = { x = x, y = y, w = badge.width, h = style.STRIP_HEIGHT },
            fillColor = fill,
            strokeColor = selected and style.HIGHLIGHT or { alpha = 0 },
            strokeWidth = selected and style.STRIP_SELECTED_BORDER_WIDTH or 0,
            roundedRectRadii = badgeRadii,
        })

        if badge.icon then
            canvas:appendElements({
                type = "image",
                frame = {
                    x = x + style.STRIP_PADDING_X,
                    y = y + (style.STRIP_HEIGHT - style.STRIP_ICON_SIZE) / 2,
                    w = style.STRIP_ICON_SIZE,
                    h = style.STRIP_ICON_SIZE,
                },
                image = badge.icon,
            })
        end

        canvas:appendElements({
            type = "text",
            frame = {
                x = x + style.STRIP_PADDING_X + badge.iconSpace,
                y = y + (style.STRIP_HEIGHT - badge.textSize.h) / 2,
                w = badge.textSize.w,
                h = badge.textSize.h,
            },
            text = hs.styledtext.new(badge.label, {
                font = STRIP_FONT,
                color = textColor,
                paragraphStyle = { alignment = "center" },
            }),
        })

        y = y + style.STRIP_HEIGHT + style.STRIP_GAP
    end
end

-- Key and description are separate text elements side by side, so a long
-- description wraps within its own column instead of bleeding under the key.
-- Row height is a fixed constant (not measured) - simpler and avoids the
-- canvas text-measurement API entirely for five short, static rows.
local function drawHelpRow(x, y, descriptionWidth, key, description)
    canvas:appendElements({
        type = "text",
        frame = { x = x, y = y, w = style.HELP_KEY_COLUMN_WIDTH - style.HELP_COLUMN_GAP, h = style.HELP_ROW_HEIGHT },
        text = hs.styledtext.new(key .. " -", {
            font = { name = style.HELP_FONT, size = style.HELP_TEXT_SIZE },
            color = style.TEXT_COLOR,
            paragraphStyle = { alignment = "right" },
        }),
    })
    canvas:appendElements({
        type = "text",
        frame = { x = x + style.HELP_KEY_COLUMN_WIDTH, y = y, w = descriptionWidth, h = style.HELP_ROW_HEIGHT },
        text = hs.styledtext.new(description, {
            font = { name = style.HELP_FONT, size = style.HELP_TEXT_SIZE },
            color = style.TEXT_COLOR,
        }),
    })
end

local function drawHelpBox(screenFrame)
    local contentWidth = style.HELP_WIDTH - (style.HELP_PADDING * 2)
    local descriptionWidth = contentWidth - style.HELP_KEY_COLUMN_WIDTH
    local boxHeight = (style.HELP_PADDING * 2)
        + (#style.HELP_ROWS * style.HELP_ROW_HEIGHT)
        + ((#style.HELP_ROWS - 1) * style.HELP_ROW_GAP)
    local boxX = screenFrame.w - style.HELP_MARGIN - style.HELP_WIDTH
    local boxY = screenFrame.h - style.HELP_MARGIN - boxHeight

    canvas:appendElements({
        type = "rectangle",
        frame = { x = boxX, y = boxY, w = style.HELP_WIDTH, h = boxHeight },
        fillColor = style.BACKGROUND_FILL,
        strokeColor = { alpha = 0 },
        roundedRectRadii = style.BACKGROUND_RADII,
    })

    local rowY = boxY + style.HELP_PADDING
    for _, row in ipairs(style.HELP_ROWS) do
        drawHelpRow(boxX + style.HELP_PADDING, rowY, descriptionWidth, row[1], row[2])
        rowY = rowY + style.HELP_ROW_HEIGHT + style.HELP_ROW_GAP
    end
end

-- state = {
--   regularWindows, minimizedWindows: the two independent lists,
--   activeList: "regular" | "minimized" - which one j/k currently drives,
--   regularSelectedIndex, minimizedSelectedIndex: each list's own cursor,
--   currentWindowIndex: index into regularWindows of the window that was
--     focused before the switcher opened (minimized windows can't be
--     focused, so this never refers to the minimized list).
-- }
function M.draw(state)
    M.clear()
    local screenFrame = hs.screen.mainScreen():frame()
    canvas = hs.canvas.new(screenFrame)
    canvas:level(hs.canvas.windowLevels.overlay)
    canvas:behavior(hs.canvas.windowBehaviors.canJoinAllSpaces)

    drawHelpBox(screenFrame)

    -- Minimized windows have no on-screen frame to trace, so only regular
    -- ones get a border here; both kinds get a badge column below.
    for i, window in ipairs(state.regularWindows) do
        -- Selected window gets the blue highlight border (only while the
        -- regular list is the active one); the window that was focused
        -- before the switcher opened gets its own subdued marker instead.
        local selected = state.activeList == "regular" and i == state.regularSelectedIndex
        local isCurrent = (i == state.currentWindowIndex)
        local color = selected and style.HIGHLIGHT or (isCurrent and style.CURRENT or style.DIM)
        local lineWidth = selected and style.SELECTED_LINE_WIDTH
            or (isCurrent and style.CURRENT_LINE_WIDTH or style.DIM_LINE_WIDTH)
        drawWindowFrame(screenFrame, window, color, lineWidth, selected)
    end

    drawBadgeColumn(
        screenFrame, state.regularWindows,
        state.activeList == "regular" and state.regularSelectedIndex or nil,
        style.HELP_MARGIN, style.HELP_MARGIN, true,
        screenFrame.h * style.STRIP_MAX_HEIGHT_RATIO,
        style.STRIP_FILL, style.STRIP_TEXT_COLOR
    )

    local minimizedMaxHeight = style.MINIMIZED_MAX_ROWS * style.STRIP_HEIGHT
        + (style.MINIMIZED_MAX_ROWS - 1) * style.STRIP_GAP
    drawBadgeColumn(
        screenFrame, state.minimizedWindows,
        state.activeList == "minimized" and state.minimizedSelectedIndex or nil,
        style.HELP_MARGIN, screenFrame.h - style.HELP_MARGIN, false,
        minimizedMaxHeight,
        style.CHIP_FILL, style.TEXT_COLOR
    )

    canvas:show()
end

return M
