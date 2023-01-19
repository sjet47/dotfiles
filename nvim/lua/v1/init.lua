local M = {}

M.config = require("v1.config")

function M.setup(user_config)
    -- Override user config
    M.config.apply(user_config)

    require("v1.basic")
    require("v1.keybinding")

    require("v1.packer")
    require("v1.plugins")
    require("v1.lsp")
end

return M
