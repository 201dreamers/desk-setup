-- Completion + suggestions (ghost text) via blink.cmp
return {
    "saghen/blink.cmp",
    dependencies = { "rafamadriz/friendly-snippets" },
    version = "*", -- use a release tag so the prebuilt fuzzy matcher is downloaded
    event = { "InsertEnter", "CmdlineEnter" },
    opts = {
        -- 'default' = built-in-like mappings: <C-y> accept, <C-space> menu,
        -- <C-n>/<C-p> navigate, <C-e> hide. See :h blink-cmp-config-keymap
        keymap = { preset = "default" },

        appearance = { nerd_font_variant = "mono" },

        completion = {
            -- show docs popup automatically after a short delay
            documentation = { auto_show = true, auto_show_delay_ms = 200 },
            -- inline "ghost text" preview of the top suggestion
            ghost_text = { enabled = true },
        },

        signature = { enabled = true },

        sources = {
            default = { "lsp", "path", "snippets", "buffer" },
        },

        -- Rust fuzzy matcher (fast, typo tolerant). Falls back to lua with a
        -- warning if the prebuilt binary is unavailable.
        fuzzy = { implementation = "prefer_rust_with_warning" },
    },
    -- On Nvim 0.11+ blink registers its LSP capabilities globally via
    -- vim.lsp.config('*', ...) automatically, so servers pick them up.
}
