-- Bootstrap lazy.nvim (plugin manager)
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
    local lazyrepo = "https://github.com/folke/lazy.nvim.git"
    local out = vim.fn.system({
        "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath,
    })
    if vim.v.shell_error ~= 0 then
        vim.api.nvim_echo({
            { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
            { out, "WarningMsg" },
        }, true, {})
        return
    end
end
vim.opt.rtp:prepend(lazypath)

-- leader is already set in core.options (must be before this file loads)
require("lazy").setup({
    spec = { { import = "plugins" } },
    install = { colorscheme = { "default" } },
    checker = { enabled = false }, -- don't auto-check for plugin updates
    change_detection = { notify = false },
})
