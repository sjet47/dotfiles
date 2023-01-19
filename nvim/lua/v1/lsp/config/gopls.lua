local common = require("v1.lsp.config.common")

return {
  on_setup = function(server)
    server.setup({
      capabilities = common.capabilities,
      flags = common.flags,
      on_attach = function(_, bufnr)
        common.keyAttach(bufnr)
        -- common.disableFormat(client)
      end,
      ---@see https://github.com/golang/tools/blob/master/gopls/doc/vim.md#neovim
      ---@see https://github.com/golang/tools/blob/master/gopls/doc/settings.md
      settings = {
        gopls = {
          analyses = {
            unusedparams = true,
          },
          staticcheck = true,
        },
      },
    })
  end,
}
