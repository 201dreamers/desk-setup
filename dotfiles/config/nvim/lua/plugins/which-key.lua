-- Kakoune-style key hints: after a prefix key (g, z, <leader>, ", ', <C-w>...)
-- a small box in the bottom-right lists the next keys and what they do.
return {
    "folke/which-key.nvim",
    event = "VeryLazy",
    opts = {
        preset = "helix", -- compact bottom-right popup, like kakoune/helix
        delay = 300, -- ms before the popup appears
        icons = { mappings = false }, -- plain text, no per-mapping icons
    },
    keys = {
        {
            "<leader>?",
            function()
                require("which-key").show({ global = false })
            end,
            desc = "buffer-local keymaps",
        },
    },
}
