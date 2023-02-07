-- A super powerful autopair plugin for Neovim that supports multiple characters
---@see https://github.com/windwp/nvim-autopairs
return {
  "windwp/nvim-autopairs",
  config = function()
    require("nvim-autopairs").setup({
      check_ts = true,
    })

    local cmp_autopairs = require("nvim-autopairs.completion.cmp")
    require("cmp").event:on("confirm_done", cmp_autopairs.on_confirm_done())
  end
}
