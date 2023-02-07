return {
    capabilities = require("cmp_nvim_lsp").default_capabilities(),
    flags = {
        debounce_text_changes = 150,
    },

    keyAttach = function(bufnr)
        local keys = require("v1.config").lsp.keys
        local opt = { noremap = true, silent = true, buffer = bufnr }

        -- TODO: move to config.diagnostic
        -- diagnostic
        vim.keymap.set("n", keys.open_flow, "<CMD>lua vim.diagnostic.open_float()<CR>")
        vim.keymap.set("n", keys.goto_next, "<CMD>lua vim.diagnostic.goto_next()<CR>")
        vim.keymap.set("n", keys.goto_prev, "<CMD>lua vim.diagnostic.goto_prev()<CR>")
        vim.keymap.set("n", keys.list, "<CMD>lua Telescope loclist<CR>")

        -- lsp
        -- vim.keymap.set("n", keys.definition, require("telescope.builtin").lsp_definitions, opt)
        -- vim.keymap.set("n", keys.declaration, vim.lsp.buf.declaration, opt)
        vim.keymap.set("n", keys.hover, vim.lsp.buf.hover, opt)
        -- vim.keymap.set("n", keys.implementation, require("telescope.builtin").lsp_implementations, opt)
        -- vim.keymap.set("n", keys.references,
        --     "<CMD>lua require'telescope.builtin'.lsp_references(require('telescope.themes').get_ivy())<CR>", opt)

        vim.keymap.set("n", keys.rename, "<CMD>lua vim.lsp.buf.rename()<CR>", opt)
        vim.keymap.set("n", keys.code_action, "<CMD>lua vim.lsp.buf.code_action()<CR>", opt)
        vim.keymap.set("n", keys.format, "<CMD>lua vim.lsp.buf.format({ async = true })<CR>", opt)
    end,

    -- Use plugin to format documents
    disableFormat = function(client)
        if vim.fn.has("nvim-0.8") == 1 then
            client.server_capabilities.documentFormattingProvider = false
            client.server_capabilities.documentRangeFormattingProvider = false
        else
            client.resolved_capabilities.document_formatting = false
            client.resolved_capabilities.document_range_formatting = false
        end
    end,
}
