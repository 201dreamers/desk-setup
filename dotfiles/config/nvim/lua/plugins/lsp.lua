-- LSP: server configs live in nvim-lspconfig's lsp/ dir; we only override what
-- we need via vim.lsp.config() and turn servers on with vim.lsp.enable().
return {
    "neovim/nvim-lspconfig",
    dependencies = { "saghen/blink.cmp" },
    event = { "BufReadPre", "BufNewFile" },
    config = function()
        -- Toggle format-on-save by flipping this (nil/false disables it).
        vim.g.format_on_save = true

        -- ---------- Diagnostics UI ----------
        vim.diagnostic.config({
            virtual_text = true,
            severity_sort = true,
            float = { border = "rounded", source = true },
            signs = {
                text = {
                    [vim.diagnostic.severity.ERROR] = "E",
                    [vim.diagnostic.severity.WARN] = "W",
                    [vim.diagnostic.severity.INFO] = "I",
                    [vim.diagnostic.severity.HINT] = "H",
                },
            },
        })

        -- ---------- Per-server overrides ----------

        -- Rust: run clippy for on-the-fly checking, enable inlay hints.
        vim.lsp.config("rust_analyzer", {
            settings = {
                ["rust-analyzer"] = {
                    check = { command = "clippy" },
                    inlayHints = { enable = true },
                },
            },
        })

        -- Lua: make lua_ls aware of Neovim's `vim` global & runtime.
        vim.lsp.config("lua_ls", {
            settings = {
                Lua = {
                    runtime = { version = "LuaJIT" },
                    diagnostics = { globals = { "vim" } },
                    workspace = {
                        library = vim.api.nvim_get_runtime_file("", true),
                        checkThirdParty = false,
                    },
                    telemetry = { enable = false },
                },
            },
        })

        -- Python completion / hover / goto (type-checking is left to mypy).
        vim.lsp.config("jedi_language_server", {})

        -- Python lint + format via Ruff's own language server.
        -- NOTE: a project-local pyproject.toml / ruff.toml overrides these.
        vim.lsp.config("ruff", {
            init_options = {
                settings = {
                    lineLength = 88,
                    lint = {
                        select = {
                            "E", -- pycodestyle errors
                            "W", -- pycodestyle warnings
                            "F", -- pyflakes
                            "I", -- isort (import sorting)
                            "B", -- flake8-bugbear
                            "C4", -- flake8-comprehensions
                            "UP", -- pyupgrade
                            "SIM", -- flake8-simplify
                            "N", -- pep8-naming
                            "PL", -- pylint (PLC/PLE/PLR/PLW)
                            "RUF", -- ruff-specific rules
                            "PTH", -- prefer pathlib
                            "RET", -- flake8-return
                            "ARG", -- unused arguments
                        },
                    },
                    format = { preview = false },
                },
            },
        })

        -- ---------- Enable servers ----------
        vim.lsp.enable({
            "rust_analyzer",
            "lua_ls",
            "jedi_language_server",
            "ruff",
        })

        -- ---------- Keymaps + format-on-save on attach ----------
        vim.api.nvim_create_autocmd("LspAttach", {
            group = vim.api.nvim_create_augroup("user_lsp_attach", { clear = true }),
            callback = function(ev)
                local buf = ev.buf
                local function map(keys, fn, desc)
                    vim.keymap.set("n", keys, fn, { buffer = buf, desc = "LSP: " .. desc })
                end

                map("gd", vim.lsp.buf.definition, "goto definition")
                map("gD", vim.lsp.buf.declaration, "goto declaration")
                map("gi", vim.lsp.buf.implementation, "goto implementation")
                map("gr", vim.lsp.buf.references, "references")
                map("K", vim.lsp.buf.hover, "hover docs")
                map("<leader>D", vim.lsp.buf.type_definition, "type definition")
                map("<leader>rn", vim.lsp.buf.rename, "rename")
                map("<leader>ca", vim.lsp.buf.code_action, "code action")
                map("<leader>f", function()
                    vim.lsp.buf.format({ async = true, filter = function(c)
                        -- For Python, only Ruff formats (jedi has no formatter).
                        if vim.bo[buf].filetype == "python" then
                            return c.name == "ruff"
                        end
                        return true
                    end })
                end, "format buffer")

                -- Inlay hints toggle (Rust etc.)
                local client = vim.lsp.get_client_by_id(ev.data.client_id)
                if client and client:supports_method("textDocument/inlayHint") then
                    map("<leader>th", function()
                        vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({ bufnr = buf }), { bufnr = buf })
                    end, "toggle inlay hints")
                end
            end,
        })

        -- Format on save (respects vim.g.format_on_save)
        vim.api.nvim_create_autocmd("BufWritePre", {
            group = vim.api.nvim_create_augroup("user_format_on_save", { clear = true }),
            callback = function(ev)
                if not vim.g.format_on_save then
                    return
                end
                vim.lsp.buf.format({
                    bufnr = ev.buf,
                    timeout_ms = 2000,
                    filter = function(c)
                        if vim.bo[ev.buf].filetype == "python" then
                            return c.name == "ruff"
                        end
                        return true
                    end,
                })
            end,
        })
    end,
}
