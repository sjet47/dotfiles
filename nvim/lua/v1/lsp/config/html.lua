local common = require("v1.lsp.config.common")

return {
  on_setup = function(server)
    server.setup({
      capabilities = common.capabilities,
      flags = common.flags,
      on_attach = function(client, bufnr)
        -- common.disableFormat(client)
        common.keyAttach(bufnr)
      end,
      init_options = {
        configurationSection = { "html", "css", "javascript" },
        embeddedLanguages = {
          css = true,
          javascript = true,
        },
        provideFormatter = true,
      },
    })
  end,
}
