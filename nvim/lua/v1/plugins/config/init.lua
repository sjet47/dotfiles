return {
  ----------------------------------------------------------------------
  --                            Dependence                            --
  ----------------------------------------------------------------------
  dependence = {
    -- Packer can manage itself
    ---@see https://github.com/wbthomason/packer.nvim
    { "wbthomason/packer.nvim" },

    -- Lua lib for neovim
    ---@see https://github.com/nvim-lua/plenary.nvim
    { "nvim-lua/plenary.nvim" },

    -- This plugin provides the same icons as well as colors for each icon
    ---@see https://github.com/nvim-tree/nvim-web-devicons
    { "nvim-tree/nvim-web-devicons" },

    -- Portable package manager for Neovim that runs everywhere Neovim runs
    -- Easily install and manage LSP servers, DAP servers, linters, and formatters
    ---@see https://github.com/williamboman/mason.nvim
    { "williamboman/mason.nvim" },

    -- Setting the commentstring option based on the cursor location in the file
    ---@see https://github.com/JoosepAlviste/nvim-ts-context-commentstring
    -- { "JoosepAlviste/nvim-ts-context-commentstring" },

    -- A completion engine plugin for neovim written in Lua
    ---@see https://github.com/hrsh7th/nvim-cmp
    { "hrsh7th/nvim-cmp" },
  },

  ----------------------------------------------------------------------
  --                            Appearance                            --
  ----------------------------------------------------------------------
  appearance = {
    -- A fancy, configurable, notification manager for NeoVim
    ---@see https://github.com/rcarriga/nvim-notify
    {
      "rcarriga/nvim-notify",
      config = function()
        require("v1.plugins.config.notify")
      end
    },

    -- -- Adds indentation guides to all lines (including empty lines)
    -- ---@see https://github.com/lukas-reineke/indent-blankline.nvim
    {
      "lukas-reineke/indent-blankline.nvim",
      config = function()
        require("v1.plugins.config.indent-blankline")
      end
    },

    -- -- Standalone UI for nvim-lsp progress. Eye candy for the impatient
    -- ---@see https://github.com/j-hui/fidget.nvim
    {
      "j-hui/fidget.nvim",
      config = function()
        require("v1.plugins.config.fidget")
      end
    },

    -- -- A snazzy buffer line (with tabpage integration) for Neovim built using lua
    -- ---@see https://github.com/akinsho/bufferline.nvim
    {
      "akinsho/bufferline.nvim",
      requires = { "nvim-tree/nvim-web-devicons" },
      config = function()
        require("v1.plugins.config.bufferline")
      end
    },

    -- -- A blazing fast and easy to configure Neovim statusline written in Lua
    -- ---@see https://github.com/nvim-lualine/lualine.nvim
    {
      "nvim-lualine/lualine.nvim",
      requires = { "nvim-tree/nvim-web-devicons" },
      config = function()
        require("v1.plugins.config.lualine")
      end
    },

    ----------------------------------------------------------------------
    --                           Colorschemes                           --
    ----------------------------------------------------------------------

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
      end
    },
  },

  ----------------------------------------------------------------------
  --                              Utility                             --
  ----------------------------------------------------------------------
  utility = {
    -- Install or upgrade all of your third-party tools
    ---@see https://github.com/WhoIsSethDaniel/mason-tool-installer.nvim
    { 'WhoIsSethDaniel/mason-tool-installer.nvim', requires = { "williamboman/mason.nvim" } },

    -- Speed up loading Lua modules in Neovim to improve startup time
    ---@see https://github.com/lewis6991/impatient.nvim
    { "lewis6991/impatient.nvim" },

    -- Bbye allows you to do delete buffers (close files) without closing your windows or messing up your layout
    ---@see https://github.com/moll/vim-bbye
    { "moll/vim-bbye" },

    -- Surround selections, stylishly
    ---@see https://github.com/kylechui/nvim-surround
    {
      "kylechui/nvim-surround",
      config = function()
        require("v1.plugins.config.nvim-surround")
      end
    },

    -- A super powerful autopair plugin for Neovim that supports multiple characters
    ---@see https://github.com/windwp/nvim-autopairs
    {
      "windwp/nvim-autopairs",
      config = function()
        require("v1.plugins.config.nvim-autopairs")
      end
    },

    -- Highlight and search for todo comments like TODO, HACK, BUG in your code base
    ---@see https://github.com/folke/todo-comments.nvim
    {
      "folke/todo-comments.nvim",
      config = function()
        require("v1.plugins.config.todo-comments")
      end
    },

    -- Draw ASCII diagrams in Neovim
    ---@see https://github.com/jbyuki/venn.nvim
    {
      "jbyuki/venn.nvim",
      config = function()
        require("v1.plugins.config.venn")
      end
    },

    -- Distraction-free coding for Neovim(AKA zen mode)
    ---@see https://github.com/folke/zen-mode.nvim
    {
      "folke/zen-mode.nvim",
      config = function()
        require("v1.plugins.config.zen-mode")
      end
    },

    -- For fluent navigation of documents and notebooks (AKA "wikis") written in markdown
    ---@see https://github.com/jakewvincent/mkdnflow.nvim
    {
      "jakewvincent/mkdnflow.nvim",
      config = function()
        require("v1.plugins.config.mkdnflow")
      end
    },

    -- Smart and Powerful commenting plugin for neovim
    ---@see https://github.com/numToStr/Comment.nvim
    -- {
    --   "numToStr/Comment.nvim",
    --   config = function()
    --     require("v1.plugins.config.comment")
    --   end
    -- },

    -- A Tree-Like File Explorer For Neovim Written In Lua
    ---@see https://github.com/nvim-tree/nvim-tree.lua
    {
      "nvim-tree/nvim-tree.lua",
      requires = { "nvim-tree/nvim-web-devicons" },
      config = function()
        require("v1.plugins.config.nvim-tree")
      end
    },
  },

  ----------------------------------------------------------------------
  --                            Telescope                             --
  ----------------------------------------------------------------------

  -- A highly extendable fuzzy finder over lists
  ---@see https://github.com/nvim-telescope/telescope.nvim
  {
    "nvim-telescope/telescope.nvim",
    requires = { "nvim-lua/plenary.nvim" },
    config = function()
      require("v1.plugins.config.telescope")
    end
  },

  -- It sets vim.ui.select to telescope. That means for example that neovim core stuff can fill the telescope picker
  ---@see https://github.com/nvim-telescope/telescope-ui-select.nvim
  { "nvim-telescope/telescope-ui-select.nvim", requires = { "nvim-telescope/telescope.nvim" } },

  -- Live grep args picker for telescope.nvim, it enables passing arguments to the grep command
  ---@see https://github.com/nvim-telescope/telescope-live-grep-args.nvim
  { "nvim-telescope/telescope-live-grep-args.nvim", requires = { "nvim-telescope/telescope.nvim" } },

  -- Watch environment variables with telescope
  ---@see https://github.com/LinArcX/telescope-env.nvim
  { "LinArcX/telescope-env.nvim", requires = { "nvim-telescope/telescope.nvim" } },

  ----------------------------------------------------------------------
  --                            Treesitter                            --
  ----------------------------------------------------------------------

  -- Provide a simple and easy way to use the interface for tree-sitter in Neovim
  -- Provide some basic functionality such as highlighting based on it
  ---@see https://github.com/nvim-treesitter/nvim-treesitter
  {
    "nvim-treesitter/nvim-treesitter",
    run = function()
      local ts_update = require("nvim-treesitter.install").update({ with_sync = true })
      ts_update()
    end,
    config = function()
      require("v1.plugins.config.treesitter")
    end,
  },

  -- Refactor modules for nvim-treesitter
  ---@see https://github.com/nvim-treesitter/nvim-treesitter-refactor
  { "nvim-treesitter/nvim-treesitter-refactor", after = { "nvim-treesitter" } },

  -- Syntax aware text-objects, select, move, swap, and peek support
  ---@see https://github.com/nvim-treesitter/nvim-treesitter-textobjects
  { "nvim-treesitter/nvim-treesitter-textobjects", after = "nvim-treesitter" },

  -- Rainbow parentheses for neovim using tree-sitter
  ---@see https://github.com/p00f/nvim-ts-rainbow
  { "p00f/nvim-ts-rainbow", after = "nvim-treesitter" },

  -- Autoclose and autorename html tag, works with html,tsx,vue,svelte,php,rescript
  ---@see https://github.com/windwp/nvim-ts-autotag
  { "windwp/nvim-ts-autotag", after = "nvim-treesitter" },

  -- Wisely add end-statement in ruby, Lua, Vimscript, etc
  ---@see https://github.com/RRethy/nvim-treesitter-endwise
  { "RRethy/nvim-treesitter-endwise", after = "nvim-treesitter" },

  ----------------------------------------------------------------------
  --                               Git                                --
  ----------------------------------------------------------------------

  -- Super fast git decorations implemented purely in lua/teal
  ---@see https://github.com/lewis6991/gitsigns.nvim
  {
    "lewis6991/gitsigns.nvim",
    config = function()
      require("v1.plugins.config.gitsigns")
    end,
  },

  coding = {
    ----------------------------------------------------------------------
    --                  Language Server Protocol(LSP)                   --
    ----------------------------------------------------------------------

    -- Bridges mason.nvim with the lspconfig plugin, making it easier to use both plugins together
    ---@see https://github.com/williamboman/mason-lspconfig.nvim
    { "williamboman/mason-lspconfig.nvim", requires = { "williamboman/mason.nvim" } },

    -- Configs for the Nvim LSP client
    ---@see https://github.com/neovim/nvim-lspconfig
    { "neovim/nvim-lspconfig" },

    -- Adds vscode-like pictograms to neovim built-in lsp
    ---@see https://github.com/onsails/lspkind.nvim
    { "onsails/lspkind-nvim" },

    -- Use Neovim as a language server to inject LSP diagnostics, code actions, and more via Lua
    ---@see https://github.com/jose-elias-alvarez/null-ls.nvim
    { "jose-elias-alvarez/null-ls.nvim" },

    -- Lua
    ---@see https://github.com/folke/neodev.nvim
    { "folke/neodev.nvim" },

    -- JSON
    ---@see b0o/schemastore.nvim
    { "b0o/schemastore.nvim" },

    -- Rust
    ---@see https://github.com/simrat39/rust-tools.nvim
    { "simrat39/rust-tools.nvim" },

    ----------------------------------------------------------------------
    --                            Completion                            --
    ----------------------------------------------------------------------

    -- Completion source for nvim-cmp
    ---@see https://github.com/saadparwaiz1/cmp_luasnip
    { "saadparwaiz1/cmp_luasnip" },

    -- Completion sources
    { "hrsh7th/cmp-vsnip" },
    { "hrsh7th/cmp-nvim-lsp" }, -- { name = nvim_lsp }
    { "hrsh7th/cmp-buffer" }, -- { name = 'buffer' },
    { "hrsh7th/cmp-path" }, -- { name = 'path' }
    { "hrsh7th/cmp-cmdline" }, -- { name = 'cmdline' }
    { "hrsh7th/cmp-nvim-lsp-signature-help" }, -- { name = 'nvim_lsp_signature_help' }

    -- Snippets that make use of the entire functionality of this plugin have to be defined in Lua
    ---@see https://github.com/L3MON4D3/LuaSnip
    { "L3MON4D3/LuaSnip" },

    -- Snippets collection for a set of different programming languages for faster development
    ---@see https://github.com/rafamadriz/friendly-snippets
    { "rafamadriz/friendly-snippets" },

    ----------------------------------------------------------------------
    --                          Code Formatter                          --
    ----------------------------------------------------------------------

    -- A format runner for Neovim
    ---@see https://github.com/mhartington/formatter.nvim
    {
      "mhartington/formatter.nvim",
      requires = { "jose-elias-alvarez/null-ls.nvim" },
      config = function()
        require("v1.format")
      end,
    },

    ----------------------------------------------------------------------
    --                   Debug Adapter Protocol(DAP)                    --
    ----------------------------------------------------------------------

    -- A Debug Adapter Protocol client implementation for Neovim
    ---@see https://github.com/mfussenegger/nvim-dap
    { "mfussenegger/nvim-dap" },

    -- Adds virtual text to find variable definitions
    {
      "theHamsta/nvim-dap-virtual-text",
      requires = { "mfussenegger/nvim-dap", "nvim-treesitter/nvim-treesitter" },
    },

    -- A UI for nvim-dap which provides a good out of the box configuration
    ---@see https://github.com/rcarriga/nvim-dap-ui
    { "rcarriga/nvim-dap-ui", requires = { "mfussenegger/nvim-dap" } },

    -- Launching go debugger (delve) and debugging individual tests.
    ---@see https://github.com/leoluz/nvim-dap-go
    { "leoluz/nvim-dap-go", requires = { "mfussenegger/nvim-dap" } },

    -- An adapter for the Neovim lua language
    ---@see https://github.com/jbyuki/one-small-step-for-vimkind
    { "jbyuki/one-small-step-for-vimkind", requires = { "mfussenegger/nvim-dap" } },

    -- Python and methods to debug individual test methods or classes
    ---@see https://github.com/mfussenegger/nvim-dap-python
    {
      "mfussenegger/nvim-dap-python",
      requires = { "mfussenegger/nvim-dap" },
      config = function()
        require("v1.dap.python")
      end
    },

    ----------------------------------------------------------------------
    --                             Neotest                              --
    ----------------------------------------------------------------------

    -- A framework for interacting with tests within NeoVim
    ---@see https://github.com/nvim-neotest/neotest
    {
      "nvim-neotest/neotest",
      config = function()
        require("v1.plugins.config.nvim-neotest")
      end,
    },

    -- A golang adapter for the Neotest framework
    ---@see https://github.com/nvim-neotest/neotest-go
    { "nvim-neotest/neotest-go" },
  },
}
