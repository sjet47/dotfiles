local common = require("v1.lsp.config.common")

return {
  on_setup = function(server)
    server.setup({
      capabilities = common.capabilities,
      flags = common.flags,
      on_attach = function(client, bufnr)
        -- use fixjson to format
        -- https://github.com/rhysd/fixjson
        common.disableFormat(client)
        common.keyAttach(bufnr)
      end,
      settings = {
        json = {
          schemas = require("schemastore").json.schemas(),
        },
      },
    })
  end,
}
