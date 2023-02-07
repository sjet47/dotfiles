local lspconfig = require("lspconfig")
local mason = require("mason")
local mason_config = require("mason-lspconfig")
local mason_tool = require("mason-tool-installer")

mason.setup({
    ui = {
        border = "rounded",
        icons = {
            package_installed = "✓",
            package_pending = "➜",
            package_uninstalled = "✗",
        },
    },
})

local lsps, tools = require("v1.lsp.config")

-- Ensure all lsp and tools are installed
local lsp_cmds = {}
for cmd, _ in pairs(lsps) do
    table.insert(lsp_cmds, cmd)
end
mason_config.setup({ ensure_installed = lsp_cmds })
mason_tool.setup({ ensure_installed = tools })

for name, config in pairs(lsps) do
    if config ~= nil and type(config) == "table" then
        -- config file must implement on_setup method
        config.on_setup(lspconfig[name])
    else
        -- or else use default params
        lspconfig[name].setup({})
    end
end

vim.diagnostic.config({
    virtual_text = true,
    signs = true,
    update_in_insert = false,
    underline = true,
    show_header = false,
    severity_sort = true,
    float = {
        source = "always",
        border = "rounded",
        style = "minimal",
        header = "",
        -- prefix = " ",
        -- max_width = 100,
        -- width = 60,
        -- height = 20,
    },
})

local signs = { Error = " ", Warn = " ", Hint = " ", Info = " " }
for type, icon in pairs(signs) do
    local hl = "DiagnosticSign" .. type
    vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = hl })
end
