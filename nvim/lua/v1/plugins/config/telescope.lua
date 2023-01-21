local cfg = require("v1.config").plugin.telescope

vim.keymap.set("n", cfg.keys.find_files, "<CMD>Telescope find_files<CR>")
vim.keymap.set("n", cfg.keys.live_grep, ":<CMD>Telescope live_grep<CR>")
vim.keymap.set("n", cfg.keys.live_grep_args, ":lua require('telescope').extensions.live_grep_args.live_grep_args()<CR>")

-- local actions = require("telescope.actions")
local telescope = require("telescope")
telescope.setup({
  defaults = {
    initial_mode = "insert",
    -- vertical , center , cursor
    layout_strategy = "horizontal",
    mappings = {
      i = {
        -- move up and down
        [cfg.keys.move_selection_next] = "move_selection_next",
        [cfg.keys.move_selection_previous] = "move_selection_previous",
        -- history
        [cfg.keys.cycle_history_next] = "cycle_history_next",
        [cfg.keys.cycle_history_prev] = "cycle_history_prev",
        -- close window
        -- ["<esc>"] = actions.close,
        [cfg.keys.close] = "close",
        [cfg.keys.preview_scrolling_up] = "preview_scrolling_up",
        [cfg.keys.preview_scrolling_down] = "preview_scrolling_down",
      },
    },
  },
  pickers = {
    find_files = {
      -- theme = "dropdown", -- can be : dropdown, cursor, ivy
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
