local cfg = require("v1.config").plugin.notify
local notify = require("notify")
vim.notify = notify

notify.setup({
  stages = cfg.stages,
  timeout = cfg.timeout,
  render = cfg.render,
})
