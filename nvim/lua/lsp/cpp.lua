local common = require("lsp.common")
common.capabilities.offsetEncoding = "utf-8"

local clangd = {
    name = "clangd",
    on_setup = function(server)
        server.setup({
            ---@see https://github.com/clangd/clangd
            capabilities = common.capabilities,
            flags = common.flags,
            on_attach = function(client, bufnr)
                common.keyAttach(bufnr)
            end,
            cmd = {
                "clangd",
                "--background-index",
                "--pch-storage=memory",
                "--clang-tidy",
                "--completion-style=detailed",
            },
            init_options = {
                clangdFileStatus = true,
                usePlaceholders = true,
                completeUnimported = true,
                semanticHighlighting = true,
            },
        })
    end,
}

return clangd
