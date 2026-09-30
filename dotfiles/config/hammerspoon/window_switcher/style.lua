-- Shared style constants for the window-switcher overlay: colors, sizes,
-- and copy. Kept separate from rendering logic in overlay.lua so tweaking
-- the look doesn't mean scrolling through drawing code.

local M = {}

-- Borders traced over each real on-screen window while the switcher is
-- open. Off: only the badge columns are drawn. Flip to true to bring the
-- frames back (colors/widths below still apply).
M.WINDOW_FRAMES_ENABLED = false
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
-- Number circles next to regular badges: same glass, a touch greyer so
-- the circle reads as separate from the badge it belongs to.
M.GLASS_NUMBER = {
    top = { white = 0.95, alpha = 0.95 },
    bottom = { white = 0.88, alpha = 0.9 },
    rim = { white = 0.7, alpha = 0.55 },
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
-- Backdrop panel behind each badge column, like the dark smoked glass
-- behind macOS's own app switcher - darker and more see-through than the
-- badges so they stand out on top of it.
M.GLASS_BACKDROP = {
    top = { white = 0.22, alpha = 0.55 },
    bottom = { white = 0.14, alpha = 0.6 },
    rim = { white = 1, alpha = 0.18 },
    rimWidth = 1,
}
M.BACKDROP_PADDING = 12
-- Vertical gap between the regular and minimized panels when both show.
M.COLUMN_GAP = 12
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

-- Badge columns (centered; regular on top, minimized below), each scrolling
-- vertically to keep its own selection visible
M.ELLIPSIS = " … "
M.STRIP_HEIGHT = 34
-- How far above the screen's vertical center the panels sit - one badge.
M.CENTER_OFFSET_Y = M.STRIP_HEIGHT
M.STRIP_GAP = 10
M.STRIP_PADDING_X = 14
M.STRIP_ICON_SIZE = 18
M.STRIP_ICON_GAP = 6
M.STRIP_MAX_LABEL_WIDTH_RATIO = 0.4
M.STRIP_MAX_HEIGHT_RATIO = 0.7
M.STRIP_TEXT_COLOR = { white = 0.12 }
M.STRIP_SELECTED_BORDER_WIDTH = 4
-- Jump-key number (1-9, 0) on the active column, drawn in its own glass
-- circle detached to the left of each badge. The circle's slot is reserved
-- on every row (numbered or not, either column) so badges never shift
-- sideways when the active list changes.
M.STRIP_NUMBER_SIZE = M.STRIP_HEIGHT
M.STRIP_NUMBER_GAP = 9
-- How far left of the screen's horizontal center the panels sit - one
-- number circle.
M.CENTER_OFFSET_X = M.STRIP_NUMBER_SIZE
M.STRIP_NUMBER_FONT = { name = ".AppleSystemUIFontBold", size = 13 }
M.STRIP_NUMBER_SELECTED_BORDER_WIDTH = M.STRIP_SELECTED_BORDER_WIDTH

-- Minimized column (below the regular one) is capped to a fixed row count rather
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
M.HELP_KEY_COLUMN_WIDTH = 95
M.HELP_COLUMN_GAP = 8
M.HELP_FONT = "Menlo"
M.HELP_TEXT_SIZE = 13
M.HELP_ROWS = {
    { "tab", "next" },
    { "j", "next" },
    { "down", "next" },
    { "S-tab", "prev" },
    { "k", "prev" },
    { "up", "prev" },
    { "1-9, 0", "jump to #" },
    { "a 1-9, 0", "jump to a#" },
    { "return", "select" },
    { "space", "select" },
    { "click", "open badge" },
    { "esc", "cancel" },
    { "?", "toggle help" },
}

M.BACKGROUND_RADII = { xRadius = 16, yRadius = 16 }

return M
