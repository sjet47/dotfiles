local C = {
    ----------------------------------------------------------------------
    --                            Appearance                            --
    ----------------------------------------------------------------------

    -- Color scheme
    --  "tokyonight"
    --  "nord"
    --  "onedark"
    --  "gruvbox"
    --  "nightfox"
    --  "nordfox"
    --  "duskfox"
    --  "dracula"
    colorscheme = "tokyonight",

    ----------------------------------------------------------------------
    --                              Plugin                              --
    ----------------------------------------------------------------------

    plugin = {
        enable_appearance = true,


        packer = {
            max_jobs = nil,
            -- Relative to nvim path
            path = "/site/pack/packer/start/packer.nvim",
            mirror = "https://github.com/",
            repo_uri = "wbthomason/packer.nvim",
            clone_timeout = 100,
            lock = false,
        },

        bufferline = {
            keys = {
                -- left / right cycle
                prev = "<C-h>",
                next = "<C-l>",
                -- close current buffer
                close = "<C-w>", -- close = "<leader>bc",
                -- close all left / right tabs
                close_left = "<leader>bh",
                close_right = "<leader>bl",
                -- close all other tabs
                close_others = "<leader>bo",
                close_pick = "<leader>bp",
            },
        },

        comment = {
            -- normal mode
            toggler = {
                line = "gcc", -- line comment
                block = "gbc", -- block comment
            },
            -- visual mode
            opleader = {
                line = "gc",
                bock = "gb",
            },
        },

        gitsign = {
            code_actions = "gitsigns",
            -- sign display
            signcolumn = true, -- Toggle with `:Gitsigns toggle_signs`
            numhl = false, -- Toggle with `:Gitsigns toggle_numhl`
            linehl = false, -- Toggle with `:Gitsigns toggle_linehl`
            word_diff = false, -- Toggle with `:Gitsigns toggle_word_diff`
            current_line_blame = false, -- Toggle with `:Gitsigns toggle_current_line_blame`
        },

        mkdnflow = {
            next_link = "gn",
            prev_link = "gp",
            next_heading = "gj",
            prev_heading = "gk",
            go_back = "<C-o>",
            follow_link = "gd",
            toggle_item = "tt",
        },

        neotest = {
            toggle = "<leader>nt",
            run = "<leader>nr",
            run_file = "<leader>nf",
            run_dap = "<leader>nd",
            run_stop = "<leader>ns",
            output_open = "<leader>gh",
        },

        notify = {
            ---@type number in millionsecond
            timeout = 3000,
            ---@type 'fade' | 'static' | 'slide'
            stages = "fade",
            ---@type  'defalut' | 'minimal' | 'simple'
            render = "minimal",
        },

        surround = {
            keys = {
                -- you surround
                normal = "ys",
                -- you surround line
                normal_cur = "yss",
                delete = "ds",
                change = "cs",
                -- visual mode
                visual = "s",
                visual_line = "gs",
                -- disable
                insert = false,
                insert_line = false,
                normal_line = false,
                normal_cur_line = false,
            },
        },

        nvimTree = {
            keys = {
                toggle = "<leader>m",
                refresh = "R",
                -- open / close --
                edit = { "o", "<2-LeftMouse>" },
                close = "<BS>",
                system_open = "<CR>",
                vsplit = "sv",
                split = "sh",
                tabnew = "gh",
                -- movement --
                parent_node = "P",
                cd = "]",
                dir_up = "[",
                prev_sibling = "<",
                next_sibling = ">",
                first_sibling = "K",
                last_sibling = "J",
                -- file toggle --
                toggle_git_ignored = "i", --.gitignore (git enable)
                toggle_dotfiles = ".", -- Hide (dotfiles)
                toggle_custom = "u", -- togglle custom config
                toggle_file_info = "gh",
                -- file operate --
                create = "a",
                remove = "d",
                rename = "r",
                cut = "x",
                copy = "c",
                paste = "p",
                copy_name = "y",
                copy_path = "Y",
                copy_absolute_path = "gy",
            },
        },

        telescope = {
            keys = {
                find_files = "<C-p>",
                live_grep = "<C-f>",
                -- super find  "xx" -tmd ---@see telescope-live-grep-args.nvim
                live_grep_args = "sf",
                -- up and down
                move_selection_next = "<C-j>",
                move_selection_previous = "<C-k>",
                -- history
                cycle_history_next = "<Down>",
                cycle_history_prev = "<Up>",
                -- close window
                close = "<esc>",
                -- scrolling in preview window
                preview_scrolling_up = "<C-u>",
                preview_scrolling_down = "<C-d>",
            },
        },

        venn = {
            keys = {
                -- toggle keymappings for venn using <leader>v
                toggle = "<leader>v",
                up = "K",
                down = "J",
                left = "H",
                right = "L",
                -- draw a box by pressing "f" with visual selection
                draw_box = "f",
            },
        },

        zen = {
            keys = {
                toggle = "<leader>z",
            },
        },

    },

    ----------------------------------------------------------------------
    --                               LSP                                --
    ----------------------------------------------------------------------

    format_on_save = true,

    lsp = {
        keys = {
            -- jumps to the declaration
            definition = "gd",
            -- jumps to the declaration, many servers do not implement this method
            declaration = false,
            -- displays hover information
            hover = "gh",
            -- lists all the implementations
            implementation = "gi",
            -- lists all the references to the symbol
            references = "gr",

            rename = "<leader>rn",
            code_action = "<leader>ca",
            format = "<leader>f",
            -- diagnostic
            open_flow = "gp",
            goto_next = "gj",
            goto_prev = "gk",
            list = "gl",
        },


        frontend = {
            enable = false,
            -- treesitter code highlight
            highlight = { "html", "css", "javascript", "typescript", "tsx", "vue" },
            -- mason lsp ensure list
            lsp = { "tsserver", "tailwindcss", "cssls", "emmet_ls", "html" },
            -- null-ls ensure list
            -- npm install -g eslint_d
            linter = "eslint_d",
            code_actions = "eslint_d",
            ---@type "eslint_d" | "prettier"
            formatter = "eslint_d",
            -- extra lsp command provided by typescript.nvim
        },

        singular = {
            cpp = {
                enable = true,
                lsp = "clangd",
                formatter = "clang-format",
                -- linter = "clangd-tidy",
            },

            golang = {
                enable = true,
                lsp = "gopls",
                formatter = "gofmt",
                linter = "golangci-lint",
            },

            rust = {
                enable = true,
                lsp = "rust_analyzer",
                formatter = "rustfmt",
            },

            python = {
                enable = true,
                lsp = "pyright",
                formatter = "black",
            },

            sh = {
                enable = true,
                lsp = "bashls",
                formatter = "shfmt",
            },

            lua = {
                enable = true,
                lsp = "sumneko_lua",
                formatter = "stylua",
            },

            json = {
                enable = true,
                lsp = "jsonls",
                formatter = "prettier",
            },

            toml = {
                enable = true,
                lsp = "taplo",
                formatter = "prettier",
            },

            yaml = {
                enable = true,
                lsp = "yamlls",
                formatter = "prettier",
            },
        },
    },

    ----------------------------------------------------------------------
    --                               Misc                               --
    ----------------------------------------------------------------------

    -- disable code hightlight on big file for performance
    max_highlight_line_count = 10000,

    -- auto switch your input method
    ---@see https://github.com/daipeihust/im-select
    enable_imselect = false,

    -- enable regexp very magic mode
    ---@see https://www.youtube.com/watch?v=VjOcINs6QWs
    enable_very_magic_search = false,

    -- fix yank problem on windows WSL2
    ---@see  https://stackoverflow.com/questions/44480829/how-to-copy-to-clipboard-in-vim-of-bash-on-windows
    fix_windows_clipboard = false,
}

function C.apply(user_config)

end

return C
