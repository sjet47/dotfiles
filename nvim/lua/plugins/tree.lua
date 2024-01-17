local function on_attach(bufnr)
    local api = require('nvim-tree.api')

    local function opts(desc)
    return { desc = 'nvim-tree: ' .. desc, buffer = bufnr, noremap = true, silent = true, nowait = true }
    end

    local function edit_or_open()
    local node = api.tree.get_node_under_cursor()

    if node.nodes ~= nil then
        -- expand or collapse folder
        api.node.open.edit()
    else
        -- open file
        api.node.open.edit()
        -- Close the tree if file was opened
        api.tree.close()
    end
    end

    -- open as vsplit on current node
    local function vsplit_preview()
    local node = api.tree.get_node_under_cursor()

    if node.nodes ~= nil then
        -- expand or collapse folder
        api.node.open.edit()
    else
        -- open file as vsplit
        api.node.open.vertical()
    end

    -- Finally refocus on tree if it was lost
    api.tree.focus()
    end

    vim.keymap.set("n", "l", edit_or_open,          opts("Edit Or Open"))
    vim.keymap.set("n", "L", vsplit_preview,        opts("Vsplit Preview"))
    vim.keymap.set("n", "h", edit_or_open,          opts("Edit Or Open"))
    vim.keymap.set("n", "H", api.tree.collapse_all, opts("Collapse All"))
end

return {
    -- A Tree-Like File Explorer For Neovim Written In Lua
    ---@see https://github.com/nvim-tree/nvim-tree.lua
    "nvim-tree/nvim-web-devicons",
    {
        "nvim-tree/nvim-tree.lua",
        version = "*",
        lazy = false,
        dependencies = {
          "nvim-tree/nvim-web-devicons",
        },
        init = function()
            -- disable netrw at the very start of your init.lua
            vim.g.loaded_netrw = 1
            vim.g.loaded_netrwPlugin = 1

            -- set termguicolors to enable highlight groups
            vim.opt.termguicolors = true

            -- global
            vim.api.nvim_set_keymap("n", "<C-h>", ":NvimTreeToggle<cr>", {silent = true, noremap = true})
        end,
        config = function(LazyPlugin, opts)
            require("nvim-tree").setup({
                hijack_cursor = true,
                sync_root_with_cwd = true,

                sort = {
                    sorter = "case_sensitive",
                },
                view = {
                    adaptive_size = false,
                    width = 24,
                    cursorline = true,
                },
                renderer = {
                    full_name = true,
                    group_empty = true,
                    full_name = true,
                    special_files = {},
                    symlink_destination = false,
                    indent_markers = {
                        enable = true,
                    },
                },
                update_focused_file = {
                    enable = true,
                    update_root = true,
                    ignore_list = { "help" },
                },
                filters = {
                    dotfiles = true,
                },
                on_attach = on_attach,
            })
        end,
    }
}
