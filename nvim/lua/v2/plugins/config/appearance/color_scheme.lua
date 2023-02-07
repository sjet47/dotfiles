return {
    -- A colorscheme creation aid for Neovim with real time feedback
    ---@see https://github.com/rktjmp/lush.nvim
    { "rktjmp/lush.nvim" },

    -- gruvbox
    { "ellisonleao/gruvbox.nvim" },

    -- nord
    { "shaunsingh/nord.nvim" },

    -- onedark
    { "ful1e5/onedark.nvim" },

    -- nightfox
    { "EdenEast/nightfox.nvim" },

    -- dracula
    { "Mofiqul/dracula.nvim" },

    -- tokyonight
    {
        "folke/tokyonight.nvim",
        config = function()
            require("v1.plugins.config.tokyonight")
            require("tokyonight").setup({
                -- The theme comes in three styles, `storm`, `moon`, a darker variant `night` and `day`
                style = "storm",
                -- Enable this to disable setting the background color
                transparent = false,
            })
        end
    },
}
