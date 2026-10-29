-- mypy type-checking bridge (mypy is a CLI, not an LSP server, so nvim-lint
-- runs it and publishes the results as Neovim diagnostics).
return {
    "mfussenegger/nvim-lint",
    event = { "BufReadPre", "BufNewFile" },
    config = function()
        local lint = require("lint")
        lint.linters_by_ft = {
            python = { "mypy" },
        }

        local group = vim.api.nvim_create_augroup("user_nvim_lint", { clear = true })
        vim.api.nvim_create_autocmd({ "BufWritePost", "BufReadPost", "InsertLeave" }, {
            group = group,
            callback = function()
                -- only run if a linter is configured for this filetype
                if lint.linters_by_ft[vim.bo.filetype] then
                    lint.try_lint()
                end
            end,
        })
    end,
}
