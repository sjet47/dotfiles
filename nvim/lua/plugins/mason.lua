return {
    {
        -- Portable package manager for Neovim that runs everywhere Neovim runs
        -- Easily install and manage LSP servers, DAP servers, linters, and formatters
        ---@see https://github.com/williamboman/mason.nvim
        "williamboman/mason.nvim",
        config = function(LazyPlugin, opts)
            require("mason").setup({
                ui = {
                    border = "rounded",
                    icons = {
                        package_installed = "✓",
                        package_pending = "➜",
                        package_uninstalled = "✗",
                    },
                }
            })
        end
    },

    {
        -- Bridges mason.nvim with the lspconfig plugin, making it easier to use both plugins together
        ---@see https://github.com/williamboman/mason-lspconfig.nvim
        "williamboman/mason-lspconfig.nvim",
        dependencies = {
            "williamboman/mason.nvim",
        },
        config = function(LazyPlugin, opts)
            local lsp_servers = {}
            for _, lsp in pairs(require("lsp")) do
                table.insert(lsp_servers, lsp.name)
            end

            require("mason-lspconfig").setup({
                -- A list of servers to automatically install if they're not already installed. Example: { "rust_analyzer@nightly", "lua_ls" }
                -- This setting has no relation with the `automatic_installation` setting.
                ---@type string[]
                ensure_installed = lsp_servers,

                -- Whether servers that are set up (via lspconfig) should be automatically installed if they're not already installed.
                -- This setting has no relation with the `ensure_installed` setting.
                -- Can either be:
                --   - false: Servers are not automatically installed.
                --   - true: All servers set up via lspconfig are automatically installed.
                --   - { exclude: string[] }: All servers set up via lspconfig, except the ones provided in the list, are automatically installed.
                --       Example: automatic_installation = { exclude = { "rust_analyzer", "solargraph" } }
                ---@type boolean
                automatic_installation = false,

                -- See `:h mason-lspconfig.setup_handlers()`
                ---@type table<string, fun(server_name: string)>?
                handlers = nil
            })
        end
    },
}
