vim.cmd("set formatoptions-=co")

vim.g.mapleader = " "
vim.g.maplocalleader = " "

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

vim.opt.updatetime = 50

-- vim.opt.conceallevel = 2
vim.opt.concealcursor = "nc"

-- Make # as comment character in robot files
vim.api.nvim_create_autocmd("FileType", {
    pattern = { "robot", "resource" },
    command = [[setlocal commentstring=#\ %s]],
})

