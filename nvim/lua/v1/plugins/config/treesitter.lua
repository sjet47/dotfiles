local cfg = require("v1.config")
local lsp = cfg.lsp.singular

-- if cfg.mirror.treesitter then
--   for _, config in pairs(require("nvim-treesitter.parsers").get_parser_configs()) do
--     config.install_info.url = config.install_info.url:gsub("https://github.com/", cfg.mirror.treesitter)
--   end
-- end
-- Folding mode
vim.opt.foldmethod = "expr"
vim.opt.foldexpr = "nvim_treesitter#foldexpr()"
vim.opt.foldenable = false
vim.opt.foldtext = "v:lua.require('v1.utils.simple-fold').simple_fold()"
-- https://stackoverflow.com/questions/8316139/how-to-set-the-default-to-unfolded-when-you-open-a-file
-- vim.opt.foldlevel = 99

-- require('ts_context_commentstring.integrations.comment_nvim').create_pre_hook()

local parserSet = {}
local ensure_installed = {}

if cfg.lsp.frontend.enable then
  for _, value in pairs(cfg.lsp.frontend.highlight) do
    table.insert(ensure_installed, value)
  end
end

if lsp.cpp.enable then
  table.insert(ensure_installed, "c")
  table.insert(ensure_installed, "cpp")
end

if lsp.golang.enable then
  table.insert(ensure_installed, "go")
end

if lsp.rust.enable then
  table.insert(ensure_installed, "rust")
end

if lsp.python.enable then
  table.insert(ensure_installed, "python")
end

if lsp.sh.enable then
  table.insert(ensure_installed, "bash")
end

if lsp.lua.enable then
  table.insert(ensure_installed, "lua")
end

if lsp.json.enable then
  table.insert(ensure_installed, "json")
end

for key, _ in pairs(parserSet) do
  table.insert(ensure_installed, key)
end

require("nvim-treesitter.configs").setup({
  sync_install = false,
  -- :TSInstallInfo
  -- ensure_installed = "maintained",
  ensure_installed = ensure_installed,

  highlight = {
    enable = true,
    additional_vim_regex_highlighting = false,
    disable = function(_, bufnr) -- Disable in large buffers
      return vim.api.nvim_buf_line_count(bufnr) > cfg.max_highlight_line_count
    end,
  },

  incremental_selection = {
    enable = false,
    keymaps = {
      init_selection = "<CR>",
      node_incremental = "<CR>",
      node_decremental = "<BS>",
      scope_incremental = "<TAB>",
    },
  },
  -- enable =
  indent = {
    enable = true,
  },
  -- p00f/nvim-ts-rainbow
  rainbow = {
    enable = true,
    -- disable = { "jsx", "cpp" }, list of languages you want to disable the plugin for
    extended_mode = true, -- Also highlight non-bracket delimiters like html tags, boolean or table: lang -> boolean
    max_file_lines = cfg.max_highlight_line_count, -- Do not enable for files with more than n lines, int
    colors = {
      "#95ca60",
      "#ee6985",
      "#D6A760",
      "#7794f4",
      "#b38bf5",
      "#7cc7fe",
    },
    -- termcolors = { } -- table of colour name strings
  },
  -- language comments
  -- Also see :comment.lua
  -- https://github.com/JoosepAlviste/nvim-ts-context-commentstring
  context_commentstring = {
    enable = true,
    enable_autocmd = false,
  },
  -- https://github.com/windwp/nvim-ts-autotag
  autotag = {
    enable = true,
  },
  -- https://github.com/RRethy/nvim-treesitter-endwise
  endwise = {
    enable = true,
  },
  -- nvim-treesitter/nvim-treesitter-refactor
  refactor = {
    highlight_definitions = {
      enable = true,
      -- Set to false if you have an `updatetime` of ~100.
      clear_on_cursor_move = true,
    },
    highlight_current_scope = { enable = false },
  },
  -- nvim-treesitter/nvim-treesitter-textobjects
  textobjects = {
    select = {
      enable = true,

      -- Automatically jump forward to textobj, similar to targets.vim
      lookahead = true,

      keymaps = {
        -- You can use the capture groups defined in textobjects.scm
        ["af"] = "@function.outer",
        ["if"] = "@function.inner",
        ["ac"] = "@class.outer",
        ["ic"] = "@class.inner",
        ["ai"] = "@conditional.outer",
        ["ii"] = "@conditional.inner",
        ["al"] = "@loop.outer",
        ["il"] = "@loop.inner",
        ["ab"] = "@block.outer",
        ["ib"] = "@block.inner",
      },
    },
    swap = {
      enable = false,
      swap_next = {
        ["<leader>a"] = "@parameter.inner",
      },
      swap_previous = {
        ["<leader>A"] = "@parameter.inner",
      },
    },
    move = {
      enable = true,
      set_jumps = true, -- whether to set jumps in the jumplist
      goto_next_start = {
        ["]m"] = "@function.outer",
        ["]]"] = "@class.outer",
      },
      goto_next_end = {
        ["]M"] = "@function.outer",
        ["]["] = "@class.outer",
      },
      goto_previous_start = {
        ["[m"] = "@function.outer",
        ["[["] = "@class.outer",
      },
      goto_previous_end = {
        ["[M"] = "@function.outer",
        ["[]"] = "@class.outer",
      },
    },
  },
})

require("nvim-treesitter.install").prefer_git = true
