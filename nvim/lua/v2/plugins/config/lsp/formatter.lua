-- A format runner for Neovim
---@see https://github.com/mhartington/formatter.nvim
return {
    "mhartington/formatter.nvim",
    requires = { "jose-elias-alvarez/null-ls.nvim" },
    config = function()
        require("v2.format")
    end,
}
