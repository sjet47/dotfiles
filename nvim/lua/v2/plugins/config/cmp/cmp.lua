-- A completion engine plugin for neovim written in Lua
---@see https://github.com/hrsh7th/nvim-cmp
return {
    { "hrsh7th/nvim-cmp" },

    -- Completion sources
    { "hrsh7th/cmp-vsnip" },
    { "hrsh7th/cmp-nvim-lsp" }, -- { name = nvim_lsp }
    { "hrsh7th/cmp-buffer" }, -- { name = 'buffer' },
    { "hrsh7th/cmp-path" }, -- { name = 'path' }
    { "hrsh7th/cmp-cmdline" }, -- { name = 'cmdline' }
    { "hrsh7th/cmp-nvim-lsp-signature-help" }, -- { name = 'nvim_lsp_signature_help' }
}
