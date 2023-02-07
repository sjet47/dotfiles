-- A fancy, configurable, notification manager for NeoVim
---@see https://github.com/rcarriga/nvim-notify
local cfg = require("v2.config").plugin.notify
return {
  "rcarriga/nvim-notify",
  config = function()
    local notify = require("notify")
    vim.notify = notify

    notify.setup({
      stages = cfg.stages,
      timeout = cfg.timeout,
      render = cfg.render,
    })
  end
}
