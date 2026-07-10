vim.cmd("set formatoptions-=co")

vim.g.mapleader = " "
vim.g.maplocalleader = " "

if pcall(require, "nvim-tree") then
    vim.g.loaded_netrw = 1
    vim.g.loaded_netrwPlugin = 1
end

vim.opt.swapfile = false
vim.opt.backup = false
vim.opt.undodir = os.getenv("HOME") .. "/.nvim/undodir"
vim.opt.undofile = true

vim.opt.colorcolumn = "80,120"
vim.opt.cursorline = true
vim.opt.signcolumn = "auto"
vim.opt.spell = false
vim.opt.wrap = false
vim.opt.ignorecase = true
vim.opt.smartcase = true

vim.opt.splitbelow = true
vim.opt.splitright = true

vim.opt.wildmenu = true
vim.opt.wildmode = "longest:full,full"

vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.shiftround = true
vim.opt.expandtab = true
vim.opt.scrolloff = 8
vim.opt.sidescrolloff = 8
vim.opt.smartindent = true

vim.opt.clipboard = ""
vim.opt.termguicolors = true

vim.opt.number = true
vim.opt.relativenumber = true

vim.g.autoformat_enabled = false -- enable or disable auto formatting at start (lsp.formatting.format_on_save must be enabled)
vim.g.cmp_enabled = true -- enable completion at start
vim.g.autopairs_enabled = true -- enable autopairs at start
vim.g.diagnostics_mode = 3 -- set the visibility of diagnostics in the UI (0=off, 1=only show in status line, 2=virtual text off, 3=all on)
vim.g.icons_enabled = true
vim.g.ui_notifications_enabled = true

vim.opt.updatetime = 50

-- vim.opt.conceallevel = 2
vim.opt.concealcursor = "nc"

-- Always keep highlight after search
vim.on_key(nil, vim.api.nvim_get_namespaces()["auto_hlsearch"])

-- Make # as comment character in robot files
vim.api.nvim_create_autocmd("FileType", {
    pattern = { "robot", "resource" },
    command = [[setlocal commentstring=#\ %s]],
})

