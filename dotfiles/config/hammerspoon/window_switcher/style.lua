-- Shared style constants for the window-switcher overlay: colors, sizes,
-- and copy. Kept separate from rendering logic in overlay.lua so tweaking
-- the look doesn't mean scrolling through drawing code.

local M = {}

-- Window-frame highlighting (borders traced over real on-screen windows),
-- also the selected badge's border - macOS's system accent blue.
M.HIGHLIGHT = { red = 0.0, green = 0.48, blue = 1.0, alpha = 0.95 }
-- Thin dark rim drawn just outside the highlight border so it stays
-- legible against light backgrounds/badges. Flip OUTLINE_ENABLED to false
-- to turn it off without touching the drawing code.
M.OUTLINE_ENABLED = false
M.OUTLINE_COLOR = { red = 0, green = 0, blue = 0, alpha = 0.85 }
M.OUTLINE_EXTRA_WIDTH = 1.5
M.DIM = { red = 1, green = 1, blue = 1, alpha = 0.35 }
M.CURRENT = { white = 0.55, alpha = 0.75 }
M.SELECTED_LINE_WIDTH = 7
M.DIM_LINE_WIDTH = 1.5
M.CURRENT_LINE_WIDTH = 3

-- Minimized-window look, used for their badge column and copied by the
-- toast notification so the two are pixel-identical in height, fill, and
-- rounding.
M.CHIP_HEIGHT = 36
M.TEXT_COLOR = { white = 0.28 }

-- Light "glass" surfaces, in the spirit of macOS's Liquid Glass with
-- transparency turned down (the Tinted look). hs.canvas can't blur what's
-- behind it, so each surface fakes glass with what one rectangle can carry
-- by itself: a top-lit translucent gradient and a soft rim. Keeping it to
-- that single element per surface means no extra canvas elements per
-- badge, so redraws cost the same as the flat look did. Opacity stays high
-- to make up for the missing blur - at ~0.75 text behind a badge bled
-- through and made labels hard to read over busy light windows.
--   top/bottom - gradient colors, lighter at the top like light from above
--   rim        - edge stroke color, rimWidth its width. Grey rather than
--                white: a white rim vanished against light windows, grey
--                still defines the edge there and reads as a highlight on
--                dark ones.
M.GLASS_STRIP = {
    top = { white = 1.0, alpha = 0.95 },
    bottom = { white = 0.93, alpha = 0.9 },
    rim = { white = 0.72, alpha = 0.55 },
    rimWidth = 1,
}
-- Minimized column and toast: same glass, greyer and a bit more
-- see-through so it reads as secondary next to the regular column.
M.GLASS_CHIP = {
    top = { white = 0.93, alpha = 0.9 },
    bottom = { white = 0.85, alpha = 0.84 },
    rim = { white = 0.66, alpha = 0.5 },
    rimWidth = 1,
}
-- Help box: the most opaque, since it holds the most small text.
M.GLASS_PANEL = {
    top = { white = 0.98, alpha = 0.96 },
    bottom = { white = 0.92, alpha = 0.93 },
    rim = { white = 0.72, alpha = 0.55 },
    rimWidth = 1,
}
-- Linear gradient direction in degrees; 90 runs top (first color) to bottom.
M.GLASS_GRADIENT_ANGLE = 90
-- Drop shadow that makes surfaces float over the windows below. Off by
-- default: CoreGraphics blurs it on every redraw, which measured +5-18ms
-- render time per frame (10 badges + help box) - flip on to trade that
-- for the depth.
M.GLASS_SHADOW_ENABLED = false
M.GLASS_SHADOW = { blurRadius = 8, color = { alpha = 0.28 }, offset = { h = -2, w = 0 } }

-- Badge columns (regular top-left, minimized bottom-left), each scrolling
-- vertically to keep its own selection visible
M.ELLIPSIS = " … "
M.STRIP_HEIGHT = 34
M.STRIP_GAP = 10
M.STRIP_PADDING_X = 14
M.STRIP_ICON_SIZE = 18
M.STRIP_ICON_GAP = 6
M.STRIP_MAX_LABEL_WIDTH_RATIO = 0.4
M.STRIP_MAX_HEIGHT_RATIO = 0.7
M.STRIP_TEXT_COLOR = { white = 0.12 }
M.STRIP_SELECTED_BORDER_WIDTH = 4
-- Jump-key number (1-9, 0) drawn in front of the icon on the active column.
M.STRIP_NUMBER_WIDTH = 10
M.STRIP_NUMBER_FONT = { name = ".AppleSystemUIFontBold", size = 13 }

-- Minimized column (bottom-left) is capped to a fixed row count rather
-- than a screen-height ratio, since it's always visible alongside the
-- regular column and shouldn't compete with it for vertical space.
M.MINIMIZED_MAX_ROWS = 5

-- Shared across every badge kind (strip, chip, toast) so text always
-- matches regardless of which one is drawn.
M.BADGE_FONT = { name = ".AppleSystemUIFontMedium", size = 13 }

-- Toast notification (drawn as its own small canvas, styled like a chip)
M.NOTIFICATION_TOP_MARGIN = 60
M.NOTIFICATION_DURATION = 0.6

-- Help box (bottom-right corner)
M.HELP_WIDTH = 250
M.HELP_MARGIN = 20
M.HELP_PADDING = 14
M.HELP_ROW_GAP = 4
M.HELP_ROW_HEIGHT = 20
M.HELP_KEY_COLUMN_WIDTH = 75
M.HELP_COLUMN_GAP = 8
M.HELP_FONT = "Menlo"
M.HELP_TEXT_SIZE = 13
M.HELP_ROWS = {
    { "j", "next" },
    { "down", "next" },
    { "k", "prev" },
    { "up", "prev" },
    { "1-9, 0", "jump to #" },
    { "return", "select" },
    { "space", "select" },
    { "click", "select" },
    { "m", "switch list" },
    { "esc", "cancel" },
    { "?", "toggle help" },
}

M.BACKGROUND_RADII = { xRadius = 16, yRadius = 16 }

return M
