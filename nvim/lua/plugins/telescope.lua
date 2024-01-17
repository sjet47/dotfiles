return {
    "nvim-lua/plenary.nvim",
    {
        -- A highly extendable fuzzy finder over lists
        ---@see https://github.com/nvim-telescope/telescope.nvim
        "nvim-telescope/telescope.nvim",
        dependencies = { "nvim-lua/plenary.nvim" },
        config = function()
            vim.keymap.set("n", "<C-p>", "<CMD>Telescope find_files<CR>")
            vim.keymap.set("n", "<C-f>", ":<CMD>Telescope live_grep<CR>")
            vim.keymap.set("n", "<sf>", ":lua require('telescope').extensions.live_grep_args.live_grep_args()<CR>")

            local telescope = require("telescope")
            telescope.setup({
                defaults = {
                    initial_mode = "insert",
                    -- vertical , center , cursor
                    layout_strategy = "horizontal",
                    mappings = {
                    i = {
                        -- move up and down
                        ["<C-j>"] = "move_selection_next",
                        ["<C-k>"] = "move_selection_previous",
                        -- history
                        ["<Down>"] = "cycle_history_next",
                        ["<Up>"] = "cycle_history_prev",
                        -- close window
                        -- ["<esc>"] = actions.close,
                        ["<Esc>"] = "close",
                        ["<C-u>"] = "preview_scrolling_up",
                        ["<C-d>"] = "preview_scrolling_down",
                    },
                    },
                },
                extensions = {
                    ["ui-select"] = {
                    require("telescope.themes").get_dropdown({
                        -- even more opts
                        initial_mode = "normal",
                    }),
                    },
                    live_grep_args = {
                    auto_quoting = false, -- enable/disable auto-quoting
                    -- mappings = { -- extend mappings
                    --   i = {
                    --     ["<C-k>"] = lga_actions.quote_prompt(),
                    --   },
                    -- },
                    },
                },
            })
            telescope.load_extension("env")
            telescope.load_extension("ui-select")
            telescope.load_extension("live_grep_args")
        end
    },
    {
        -- It sets vim.ui.select to telescope. That means for example that neovim core stuff can fill the telescope picker
        ---@see https://github.com/nvim-telescope/telescope-ui-select.nvim
        "nvim-telescope/telescope-ui-select.nvim",
        dependencies = { "nvim-telescope/telescope.nvim" }
    },
    {
        -- Live grep args picker for telescope.nvim, it enables passing arguments to the grep command
        ---@see https://github.com/nvim-telescope/telescope-live-grep-args.nvim
        "nvim-telescope/telescope-live-grep-args.nvim",
        dependencies = { "nvim-telescope/telescope.nvim" }
    },
        -- Watch environment variables with telescope
        ---@see https://github.com/LinArcX/telescope-env.nvim
    {
        "LinArcX/telescope-env.nvim",
        dependencies = { "nvim-telescope/telescope.nvim" }
    },

}
