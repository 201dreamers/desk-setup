-- Shared style constants for the window-switcher overlay: colors, sizes,
-- and copy. Kept separate from rendering logic in overlay.lua so tweaking
-- the look doesn't mean scrolling through drawing code.

local M = {}

-- Window-frame highlighting (borders traced over real on-screen windows)
M.HIGHLIGHT = { red = 0.10, green = 0.30, blue = 0.60, alpha = 0.9 }
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
M.CHIP_FILL = { white = 0.35, alpha = 0.95 }
M.TEXT_COLOR = { white = 0.82 }

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
M.STRIP_FILL = { white = 0.75, alpha = 0.95 }
M.STRIP_TEXT_COLOR = { white = 0.16 }
M.STRIP_SELECTED_BORDER_WIDTH = 4

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
    { "return", "select" },
    { "space", "select" },
    { "click", "select" },
    { "m", "switch list" },
    { "esc", "cancel" },
    { "?", "toggle help" },
}

M.BACKGROUND_FILL = { red = 0.05, green = 0.05, blue = 0.05, alpha = 0.85 }
M.BACKGROUND_RADII = { xRadius = 10, yRadius = 10 }

return M
