-- Draws the switcher overlay: optionally a rectangle traced over each real
-- window's on-screen frame (style.WINDOW_FRAMES_ENABLED; minimized windows
-- have none, so they're skipped), two independent vertically-scrollable
-- badge columns stacked in the center of the screen - regular windows on
-- top, minimized windows below in a greyer glass style, both always
-- visible - with the current selection marked by a blue border in the
-- regular column, and a help box in the bottom-right corner.
--
-- Only owns rendering - it knows nothing about how the window lists or the
-- selection indices came to be, so styling can change without touching
-- sources.lua or controller.lua.

local sources = require("window_switcher.sources")
local style = require("window_switcher.style")

local M = {}

-- One canvas for the overlay's whole lifetime: draw() swaps its elements
-- and clear() only hides it, since creating a canvas (a real window) on
-- every open and every j/k press cost more than redrawing into one.
local canvas = nil
-- Elements for the frame being drawn, collected by add() and handed to the
-- canvas in one replaceElements() call at the end of M.draw.
local elements = {}
local notificationCanvas = nil
local clickHandler = nil

local function add(element)
    elements[#elements + 1] = element
end

-- Creates the canvas on first use, and follows the main screen after that
-- (a different display, or a resolution change).
local function ensureCanvas(screenFrame)
    if not canvas then
        canvas = hs.canvas.new(screenFrame)
        canvas:level(hs.canvas.windowLevels.overlay)
        canvas:behavior(hs.canvas.windowBehaviors.canJoinAllSpaces)
        canvas:canvasMouseEvents(false, true, false, false)
        -- Badges and their number circles carry an id "<list>:<index>"
        -- (see drawBadgeColumn); a click anywhere else reports "_canvas_".
        canvas:mouseCallback(function(_, message, id)
            if message ~= "mouseUp" or not clickHandler then
                return
            end
            local list, index = tostring(id):match("^(%a+):(%d+)$")
            clickHandler(list and { list = list, index = tonumber(index) } or nil)
        end)
        return
    end
    local f = canvas:frame()
    if f.x ~= screenFrame.x or f.y ~= screenFrame.y or f.w ~= screenFrame.w or f.h ~= screenFrame.h then
        canvas:frame(screenFrame)
    end
end

function M.clear()
    if canvas then
        canvas:hide()
    end
end

-- Builds the canvas and loads text layout up front, so the first open after
-- a config (re)load doesn't pay for either.
function M.prewarm()
    ensureCanvas(hs.screen.mainScreen():frame())
    canvas:minimumTextSize(hs.styledtext.new("prewarm", { font = style.BADGE_FONT }))
end

-- Registers a callback fired on left click anywhere in the overlay. It gets
-- { list = "regular" | "minimized", index } when a badge (or its number
-- circle) was clicked, or nil for a click anywhere else. Stored
-- separately from `canvas` since the canvas itself gets torn down and
-- created lazily (see ensureCanvas), but the handler should stick around.
function M.onClick(handler)
    clickHandler = handler
end

-- One rectangle styled as a glass surface (see style.GLASS_*): gradient
-- fill, rim stroke and (optional) shadow all ride on this single element. Pass
-- strokeColor/strokeWidth to swap the rim for another border, e.g. the
-- selection highlight.
local function glassRect(glass, frame, radii, strokeColor, strokeWidth)
    local element = {
        type = "rectangle",
        frame = frame,
        fillGradient = "linear",
        fillGradientAngle = style.GLASS_GRADIENT_ANGLE,
        fillGradientColors = { glass.top, glass.bottom },
        strokeColor = strokeColor or glass.rim,
        strokeWidth = strokeWidth or glass.rimWidth,
        roundedRectRadii = radii,
    }
    -- Only set when on: every attribute is converted into the canvas on
    -- each redraw, so leaving these off keeps the element as cheap as the
    -- old flat fill.
    if style.GLASS_SHADOW_ENABLED then
        element.withShadow = true
        element.shadow = style.GLASS_SHADOW
    end
    return element
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
    notificationCanvas:appendElements(glassRect(
        style.GLASS_CHIP,
        { x = 0, y = 0, w = width, h = style.CHIP_HEIGHT },
        { xRadius = style.CHIP_HEIGHT / 2, yRadius = style.CHIP_HEIGHT / 2 }
    ))
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
        add({
            type = "rectangle",
            frame = frame,
            fillColor = { alpha = 0 },
            strokeColor = style.OUTLINE_COLOR,
            strokeWidth = lineWidth + style.OUTLINE_EXTRA_WIDTH,
            roundedRectRadii = radii,
        })
    end

    add({
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
-- display. Window i gets jump position numberOffset + i, labelled by
-- jumpLabel (nil for no label; drawn in a separate circle, so it doesn't
-- count toward the badge's own width).
local function buildBadges(windows, maxLabelWidth, numberOffset, jumpLabel)
    local badges = {}
    for i, window in ipairs(windows) do
        local number = jumpLabel(numberOffset + i)
        local label = truncateMiddle(sources.label(window), STRIP_MEASURE_STYLE, maxLabelWidth)
        local textSize = canvas:minimumTextSize(hs.styledtext.new(label, STRIP_MEASURE_STYLE))
        local icon = sources.appIcon(window)
        local iconSpace = icon and (style.STRIP_ICON_SIZE + style.STRIP_ICON_GAP) or 0
        table.insert(badges, {
            originalIndex = i,
            label = label,
            icon = icon,
            iconSpace = iconSpace,
            number = number,
            textSize = textSize,
            width = textSize.w + iconSpace + style.STRIP_PADDING_X * 2,
        })
    end
    return badges
end

-- Total height of `count` stacked items of `itemSize`, `gap` apart.
local function stackedHeight(count, itemSize, gap)
    return count * itemSize + math.max(count - 1, 0) * gap
end

-- How many badge rows fit within maxHeight - a fixed slot count.
local function visibleRowCount(maxHeight)
    local rowSize = style.STRIP_HEIGHT + style.STRIP_GAP
    return math.max(1, math.floor((maxHeight + style.STRIP_GAP) / rowSize))
end

-- A fixed-size window of `rows` list indices centered on anchorPos (anchor
-- sits at the middle slot), clamped to stay inside [1, count]. The anchor's
-- slot within the window only shifts when clamping kicks in near either
-- edge of the list - everywhere else it's the same slot every time.
local function clampedRange(count, anchorPos, rows)
    rows = math.min(rows, count)
    local anchorSlot = math.min(math.ceil(rows / 2), rows)

    local first = anchorPos - (anchorSlot - 1)
    local last = first + rows - 1

    if first < 1 then
        last = last + (1 - first)
        first = 1
    end
    if last > count then
        first = first - (last - count)
        last = count
    end
    first = math.max(first, 1)

    return first, last
end

-- Vertical, left-aligned stack of pill badges, one per window in `windows`,
-- on a backdrop panel like macOS's own switcher. Split into layout and
-- draw so M.draw can size both columns first and then center them on
-- screen together. selectedIndex highlights one badge with a blue border;
-- pass nil to render the whole column with nothing highlighted (the list
-- that can't be selected, i.e. minimized windows). Both columns are
-- numbered, continuing from one to the next via numberOffset.
--
-- The selected badge stays in the same fixed slot for most of the list -
-- only near the very top or bottom, where the fixed-size window would run
-- past the list's edge, does its slot shift a little to avoid empty rows.
-- opts = { list, windows, selectedIndex, numberOffset, jumpLabel,
--         maxHeight, glass, numberGlass, textColor }
-- (list is "regular" | "minimized", reported back on click)
-- (numberGlass is optional - number circles fall back to glass)
-- (see call sites in M.draw for what each field means) - bundled into a table
-- since several are same-typed neighbors (glass/textColor) that a
-- positional call could silently transpose.
--
-- Returns nil for an empty list, otherwise the layout for drawBadgeColumn
-- with the panel's natural size in width/height. Width follows the widest
-- badge in the whole list, not just the visible rows, so the panel doesn't
-- resize while scrolling.
local function layoutBadgeColumn(screenFrame, opts)
    local maxLabelWidth = screenFrame.w * style.STRIP_MAX_LABEL_WIDTH_RATIO
    local badges = buildBadges(opts.windows, maxLabelWidth, opts.numberOffset, opts.jumpLabel)
    if #badges == 0 then
        return nil
    end

    local selectedPos = nil
    for i, badge in ipairs(badges) do
        if badge.originalIndex == opts.selectedIndex then
            selectedPos = i
            break
        end
    end

    local rows = visibleRowCount(opts.maxHeight)
    local first, last = clampedRange(#badges, selectedPos or 1, rows)

    local maxBadgeWidth = 0
    for _, badge in ipairs(badges) do
        maxBadgeWidth = math.max(maxBadgeWidth, badge.width)
    end
    local padding = style.BACKDROP_PADDING
    return {
        opts = opts,
        badges = badges,
        selectedPos = selectedPos,
        first = first,
        last = last,
        width = style.STRIP_NUMBER_SIZE + style.STRIP_NUMBER_GAP + maxBadgeWidth + padding * 2,
        height = stackedHeight(last - first + 1, style.STRIP_HEIGHT, style.STRIP_GAP) + padding * 2,
    }
end

-- Draws a column laid out by layoutBadgeColumn with its panel's top-left
-- corner at (panelX, panelY), panelWidth wide (may exceed the layout's own
-- width, so stacked columns can share one width).
local function drawBadgeColumn(layout, panelX, panelY, panelWidth)
    local opts, badges, selectedPos = layout.opts, layout.badges, layout.selectedPos
    local padding = style.BACKDROP_PADDING
    -- Concentric with the pill badges inside it.
    local panelRadius = style.STRIP_HEIGHT / 2 + padding
    add(glassRect(
        style.GLASS_BACKDROP,
        { x = panelX, y = panelY, w = panelWidth, h = layout.height },
        { xRadius = panelRadius, yRadius = panelRadius }
    ))

    local x = panelX + padding
    local y = panelY + padding

    local numberRadii = { xRadius = style.STRIP_NUMBER_SIZE / 2, yRadius = style.STRIP_NUMBER_SIZE / 2 }
    local badgeX = x + style.STRIP_NUMBER_SIZE + style.STRIP_NUMBER_GAP

    for i = layout.first, layout.last do
        local badge = badges[i]
        local selected = (i == selectedPos)
        local badgeRadii = { xRadius = style.STRIP_HEIGHT / 2, yRadius = style.STRIP_HEIGHT / 2 }
        -- Clicks on the circle or badge (or the text/icon on top of them)
        -- come back to the mouse callback with this id.
        local clickId = opts.list .. ":" .. badge.originalIndex

        if badge.number then
            local circleY = y + (style.STRIP_HEIGHT - style.STRIP_NUMBER_SIZE) / 2
            local circle = glassRect(
                opts.numberGlass or opts.glass,
                { x = x, y = circleY, w = style.STRIP_NUMBER_SIZE, h = style.STRIP_NUMBER_SIZE },
                numberRadii,
                selected and style.HIGHLIGHT or nil,
                selected and style.STRIP_NUMBER_SELECTED_BORDER_WIDTH or nil
            )
            circle.id = clickId
            circle.trackMouseUp = true
            add(circle)
            add({
                type = "text",
                frame = {
                    x = x,
                    y = y + (style.STRIP_HEIGHT - badge.textSize.h) / 2,
                    w = style.STRIP_NUMBER_SIZE,
                    h = badge.textSize.h,
                },
                text = hs.styledtext.new(badge.number, {
                    font = style.STRIP_NUMBER_FONT,
                    color = opts.textColor,
                    paragraphStyle = { alignment = "center" },
                }),
            })
        end

        if selected and style.OUTLINE_ENABLED then
            add({
                type = "rectangle",
                frame = { x = badgeX, y = y, w = badge.width, h = style.STRIP_HEIGHT },
                fillColor = { alpha = 0 },
                strokeColor = style.OUTLINE_COLOR,
                strokeWidth = style.STRIP_SELECTED_BORDER_WIDTH + style.OUTLINE_EXTRA_WIDTH,
                roundedRectRadii = badgeRadii,
            })
        end

        local pill = glassRect(
            opts.glass,
            { x = badgeX, y = y, w = badge.width, h = style.STRIP_HEIGHT },
            badgeRadii,
            selected and style.HIGHLIGHT or nil,
            selected and style.STRIP_SELECTED_BORDER_WIDTH or nil
        )
        pill.id = clickId
        pill.trackMouseUp = true
        add(pill)

        if badge.icon then
            add({
                type = "image",
                frame = {
                    x = badgeX + style.STRIP_PADDING_X,
                    y = y + (style.STRIP_HEIGHT - style.STRIP_ICON_SIZE) / 2,
                    w = style.STRIP_ICON_SIZE,
                    h = style.STRIP_ICON_SIZE,
                },
                image = badge.icon,
            })
        end

        add({
            type = "text",
            frame = {
                x = badgeX + style.STRIP_PADDING_X + badge.iconSpace,
                y = y + (style.STRIP_HEIGHT - badge.textSize.h) / 2,
                w = badge.textSize.w,
                h = badge.textSize.h,
            },
            text = hs.styledtext.new(badge.label, {
                font = STRIP_FONT,
                color = opts.textColor,
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
    add({
        type = "text",
        frame = { x = x, y = y, w = style.HELP_KEY_COLUMN_WIDTH - style.HELP_COLUMN_GAP, h = style.HELP_ROW_HEIGHT },
        text = hs.styledtext.new(key .. " -", {
            font = { name = style.HELP_FONT, size = style.HELP_TEXT_SIZE },
            color = style.TEXT_COLOR,
            paragraphStyle = { alignment = "right" },
        }),
    })
    add({
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
        + stackedHeight(#style.HELP_ROWS, style.HELP_ROW_HEIGHT, style.HELP_ROW_GAP)
    local boxX = screenFrame.w - style.HELP_MARGIN - style.HELP_WIDTH
    local boxY = screenFrame.h - style.HELP_MARGIN - boxHeight

    add(glassRect(
        style.GLASS_PANEL,
        { x = boxX, y = boxY, w = style.HELP_WIDTH, h = boxHeight },
        style.BACKGROUND_RADII
    ))

    local rowY = boxY + style.HELP_PADDING
    for _, row in ipairs(style.HELP_ROWS) do
        drawHelpRow(boxX + style.HELP_PADDING, rowY, descriptionWidth, row[1], row[2])
        rowY = rowY + style.HELP_ROW_HEIGHT + style.HELP_ROW_GAP
    end
end

-- state = {
--   regularWindows, minimizedWindows: the two independent lists,
--   selectedIndex: index into regularWindows of the highlighted window
--     (minimized windows are never selected),
--   jumpLabel(position): key label for a jump position (regular windows
--     first, then minimized), or nil when it has none,
--   currentWindowIndex: index into regularWindows of the window that was
--     focused before the switcher opened (minimized windows can't be
--     focused, so this never refers to the minimized list).
--   helpVisible: whether the "?"-toggled help box should be drawn.
-- }
function M.draw(state)
    local screenFrame = hs.screen.mainScreen():frame()
    ensureCanvas(screenFrame)
    elements = {}

    if state.helpVisible then
        drawHelpBox(screenFrame)
    end

    -- Minimized windows have no on-screen frame to trace, so only regular
    -- ones get a border here; both kinds get a badge column below.
    for i, window in ipairs(style.WINDOW_FRAMES_ENABLED and state.regularWindows or {}) do
        -- Selected window gets the blue highlight border; the window that
        -- was focused before the switcher opened gets its own subdued
        -- marker instead.
        local selected = (i == state.selectedIndex)
        local isCurrent = (i == state.currentWindowIndex)
        local color = selected and style.HIGHLIGHT or (isCurrent and style.CURRENT or style.DIM)
        local lineWidth = selected and style.SELECTED_LINE_WIDTH
            or (isCurrent and style.CURRENT_LINE_WIDTH or style.DIM_LINE_WIDTH)
        drawWindowFrame(screenFrame, window, color, lineWidth, selected)
    end

    -- Both columns are stacked in the middle of the screen - regular on
    -- top, minimized below - sharing one width and centered together as a
    -- group, so the pair looks like a single switcher.
    local minimized = layoutBadgeColumn(screenFrame, {
        list = "minimized",
        windows = state.minimizedWindows,
        selectedIndex = nil,
        numberOffset = #state.regularWindows,
        jumpLabel = state.jumpLabel,
        maxHeight = stackedHeight(style.MINIMIZED_MAX_ROWS, style.STRIP_HEIGHT, style.STRIP_GAP),
        glass = style.GLASS_CHIP, textColor = style.TEXT_COLOR,
    })
    -- The regular column gets whatever of the height budget the minimized
    -- panel leaves, so the pair never outgrows it.
    local regularMaxHeight = screenFrame.h * style.STRIP_MAX_HEIGHT_RATIO - style.BACKDROP_PADDING * 2
    if minimized then
        regularMaxHeight = regularMaxHeight - minimized.height - style.COLUMN_GAP
    end
    local regular = layoutBadgeColumn(screenFrame, {
        list = "regular",
        windows = state.regularWindows,
        selectedIndex = state.selectedIndex,
        numberOffset = 0,
        jumpLabel = state.jumpLabel,
        maxHeight = regularMaxHeight,
        glass = style.GLASS_STRIP, numberGlass = style.GLASS_NUMBER, textColor = style.STRIP_TEXT_COLOR,
    })

    local columns = {}
    for _, layout in ipairs({ regular or false, minimized or false }) do
        if layout then
            columns[#columns + 1] = layout
        end
    end
    local width, height = 0, style.COLUMN_GAP * (#columns - 1)
    for _, layout in ipairs(columns) do
        width = math.max(width, layout.width)
        height = height + layout.height
    end
    -- Sits a little left of and above true center (by style.CENTER_OFFSET_X
    -- and CENTER_OFFSET_Y), where the eye lands more naturally.
    local x = (screenFrame.w - width) / 2 - style.CENTER_OFFSET_X
    local y = (screenFrame.h - height) / 2 - style.CENTER_OFFSET_Y
    for _, layout in ipairs(columns) do
        drawBadgeColumn(layout, x, y, width)
        y = y + layout.height + style.COLUMN_GAP
    end

    -- controller.lua never draws with both lists empty, so there's always
    -- at least one badge here (replaceElements rejects an empty list).
    canvas:replaceElements(elements)
    canvas:show()
end

return M
