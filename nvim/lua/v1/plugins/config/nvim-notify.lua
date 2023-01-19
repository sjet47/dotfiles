local cfg = require("v1.config").plugin.notify

return {
  stages = cfg.stages,
  timeout = cfg.timeout,
  render = cfg.render,
}
