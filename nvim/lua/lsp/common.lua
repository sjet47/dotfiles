return {
    capabilities = require("cmp_nvim_lsp").default_capabilities(),
    keyAttach = function(bufnr)
        -- diagnostic
        -- vim.keymap.set("n", "gp", "<CMD>lua vim.diagnostic.open_float()<CR>")
        -- vim.keymap.set("n", "gj", "<CMD>lua vim.diagnostic.goto_next()<CR>")
        -- vim.keymap.set("n", "gk", "<CMD>lua vim.diagnostic.goto_prev()<CR>")
        -- vim.keymap.set("n", "gl", "<CMD>lua Telescope loclist<CR>")

        -- lsp
        vim.keymap.set("n", "gd", require("telescope.builtin").lsp_definitions, opt)
        -- vim.keymap.set("n", keys.declaration, vim.lsp.buf.declaration, opt)
        vim.keymap.set("n", "gh", vim.lsp.buf.hover, opt)
        -- vim.keymap.set("n", keys.implementation, require("telescope.builtin").lsp_implementations, opt)
        -- vim.keymap.set("n", keys.references,
        --     "<CMD>lua require'telescope.builtin'.lsp_references(require('telescope.themes').get_ivy())<CR>", opt)

        -- vim.keymap.set("n", "<leader>rn", "<CMD>lua vim.lsp.buf.rename()<CR>", opt)
        -- vim.keymap.set("n", "<leader>ca", "<CMD>lua vim.lsp.buf.code_action()<CR>", opt)
        -- vim.keymap.set("n", "<C-I>", "<CMD>lua vim.lsp.buf.format({ async = true })<CR>", opt)
    end
}
