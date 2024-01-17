return {
    {
        "rcarriga/nvim-notify",
        init = function()
            vim.opt.termguicolors = true
        end,
        config = function()
            require("notify").setup({
                fps = 60,
                background_colour = "#000000",
                stages = "fade_in_slide_out",
            })
        end
    }
}
