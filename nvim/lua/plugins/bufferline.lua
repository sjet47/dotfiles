return {
    'akinsho/bufferline.nvim',
    version = "*",
    event = 'BufReadPre',
    dependencies = 'nvim-tree/nvim-web-devicons',
    config = function(LazyPlugin, opts)
        vim.opt.termguicolors = true
        vim.opt.mousemoveevent = true
        require("bufferline").setup({
            options = {
                hover = {
                    enabled = true,
                    delay = 50,
                    reveal = {"close"},
                }
            }
        })
    end,
}
