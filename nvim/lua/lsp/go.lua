local common = require("lsp.common")
local gopls = {
    name = "gopls",
    on_setup = function(server)
        server.setup({
            ---@see https://github.com/golang/tools/blob/master/gopls/doc/vim.md#neovim
            ---@see https://github.com/golang/tools/blob/master/gopls/doc/settings.md
            capabilities = common.capabilities,
            flags = common.flags,
            on_attach = function(client, bufnr)
                client.server_capabilities.semanticTokensProvider = {
                    full = true,
                    legend = {
                        tokenTypes = { 'namespace', 'type', 'class', 'enum', 'interface', 'struct', 'typeParameter', 'parameter', 'variable', 'property', 'enumMember', 'event', 'function', 'method', 'macro', 'keyword', 'modifier', 'comment', 'string', 'number', 'regexp', 'operator', 'decorator' },
                        tokenModifiers = { 'declaration', 'definition', 'readonly', 'static', 'deprecated', 'abstract', 'async', 'modification', 'documentation', 'defaultLibrary'}
                    }
                }
                common.keyAttach(bufnr)
            end,
            settings = {
                gopls = {
                    analyses = {
                        unusedparams = true,
                    },
                    staticcheck = true,
                    semanticTokens = true,
                    hints = {
                        assignVariableTypes = true,
                        compositeLiteralFields = true,
                        compositeLiteralTypes = true,
                        constantValues = true,
                        functionTypeParameters = true,
                        parameterNames = true,
                        rangeVariableTypes = true,
                    },
                },
            },
        })
    end,
}

return gopls
