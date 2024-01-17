return {
    -- A blazing fast and easy to configure Neovim statusline written in Lua
    ---@see https://github.com/nvim-lualine/lualine.nvim
    'nvim-lualine/lualine.nvim',
    dependencies = { 'nvim-tree/nvim-web-devicons' },
    config = function()
        require("lualine").setup({})
    end
}
