local common = require("v1.lsp.config.common")
common.capabilities.offsetEncoding = "utf-8"

return {
  on_setup = function(server)
    server.setup({
      capabilities = common.capabilities,
      flags = common.flags,
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
      on_attach = function(client, bufnr)
        common.disableFormat(client)
        common.keyAttach(bufnr)
      end,
    })
  end,
}
