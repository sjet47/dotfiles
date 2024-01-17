local common = require("lsp.common")

local rust_analyzer = {
    name = "rust_analyzer",
    on_setup = function(server)
        server.setup({
            on_attach = function(client, bufnr)
                -- common.disableFormat(client)
                require('completion').on_attach(client)
                common.keyAttach(bufnr)
            end,
            settings = {
                ["rust-analyzer"] = {
                    imports = {
                        granularity = {
                            group = "module",
                        },
                        prefix = "self",
                    },
                    cargo = {
                        buildScripts = {
                            enable = true,
                        },
                    },
                    procMacro = {
                        enable = true
                    },
                }
            }
        })
    end
}

return rust_analyzer
