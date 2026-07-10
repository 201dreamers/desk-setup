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
map("n", "<C-h>", "<C-w><Left>")
map("n", "<C-j>", "<C-w><Down>")
map("n", "<C-k>", "<C-w><Up>")
map("n", "<C-l>", "<C-w><Right>")

map("n", "<M-Left>", ":vertical resize -5<cr>")
map("n", "<M-Right>", ":vertical resize +5<cr>")
map("n", "<M-Up>", ":resize +5<cr>")
map("n", "<M-Down>", ":resize -5<cr>")

-- Buffers
-- map("n", "H", ":bp<cr>")
-- map("n", "L", ":bn<cr>")
map("n", "<leader>x", ":bn<cr>:bd#<cr>", { desc = "close buffer" })

-- General better movement
map("n", "J", "mzJ`z")
map("n", "n", "nzz")
map("n", "N", "Nzz")
map("n", "<C-d>", "<C-d>zz")
map("n", "<C-u>", "<C-u>zz")
map("v", ">", ">gv")
map("v", "<", "<gv")
map("v", "<M-k>", ":m '<-2<cr>gv=gv")
map("v", "<M-j>", ":m '>+1<cr>gv=gv")

-- Copy / paste
map({ "n", "v" }, "<leader>y", [["+y]], { desc = "copy to clipboard" })
map({ "n", "v" }, "<leader>d", [["_d]], { desc = "delete to void" })
map("n", "<leader>Y", [["+Y]], { desc = "line to clipboard" })
map("x", "<leader>p", [["_dP]], { desc = "paste over" })

-- map("n", "<leader>t", [[:%s/\s\+$//e<cr>]], { desc = "remove trailing spaces" })
