local map = vim.keymap.set

-- ----------------
-- General mappings
-- ----------------
-- Add here mapping not related to plugins

-- Default explorer
map("n", "<leader>e", ":Explore<cr>", { desc = "explorer" })

-- Save file
map("n", "<leader>w", ":w<cr>", { desc = "save file" })

-- Moving around windows
map("n", "<C-h>", "<C-w><Left>", { desc = "window left" })
map("n", "<C-j>", "<C-w><Down>", { desc = "window down" })
map("n", "<C-k>", "<C-w><Up>", { desc = "window up" })
map("n", "<C-l>", "<C-w><Right>", { desc = "window right" })

map("n", "<M-Left>", ":vertical resize -5<cr>", { desc = "narrow window" })
map("n", "<M-Right>", ":vertical resize +5<cr>", { desc = "widen window" })
map("n", "<M-Up>", ":resize +5<cr>", { desc = "taller window" })
map("n", "<M-Down>", ":resize -5<cr>", { desc = "shorter window" })

-- Buffers
-- map("n", "H", ":bp<cr>")
-- map("n", "L", ":bn<cr>")
map("n", "<leader>x", ":bn<cr>:bd#<cr>", { desc = "close buffer" })

-- General better movement
map("n", "J", "mzJ`z", { desc = "join lines, keep cursor" })
map("n", "n", "nzz", { desc = "next match, centered" })
map("n", "N", "Nzz", { desc = "prev match, centered" })
map("n", "<C-d>", "<C-d>zz", { desc = "half page down, centered" })
map("n", "<C-u>", "<C-u>zz", { desc = "half page up, centered" })
map("v", ">", ">gv", { desc = "indent, keep selection" })
map("v", "<", "<gv", { desc = "dedent, keep selection" })
map("v", "<M-k>", ":m '<-2<cr>gv=gv", { desc = "move selection up" })
map("v", "<M-j>", ":m '>+1<cr>gv=gv", { desc = "move selection down" })

-- Copy / paste
map({ "n", "v" }, "<leader>y", [["+y]], { desc = "copy to clipboard" })
map({ "n", "v" }, "<leader>d", [["_d]], { desc = "delete to void" })
map("n", "<leader>Y", [["+Y]], { desc = "line to clipboard" })
map("x", "<leader>p", [["_dP]], { desc = "paste over" })

-- map("n", "<leader>t", [[:%s/\s\+$//e<cr>]], { desc = "remove trailing spaces" })
