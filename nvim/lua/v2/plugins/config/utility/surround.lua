-- Surround selections, stylishly
---@see https://github.com/kylechui/nvim-surround
local cfg = require("v2.config").plugin.surround
return {
    "kylechui/nvim-surround",
    config = function()
        require("nvim-surround").setup({
            keymaps = vim.tbl_deep_extend("force", {
                -- you surround
                normal = "ys",
                -- you surround line
                normal_cur = "yss",

                delete = "ds",
                change = "cs",

                visual = "s",
                visual_line = "gs",

                insert = false,
                insert_line = false,
                -- you surround with delimiter
                normal_line = false,
                -- you surround line with delimiter
                normal_cur_line = false,
            }, cfg.keys),
        })
    end
}
