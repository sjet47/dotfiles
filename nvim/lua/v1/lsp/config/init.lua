local cfg = require("v1.config").lsp
-- all supported lsp server for now
-- mason-lspconfig uses the `lspconfig` server names in the APIs it exposes - not `mason.nvim` package names
---@see https://github.com/williamboman/mason-lspconfig.nvim/blob/main/doc/server-mapping.md
local all_lsps = {
    sumneko_lua = require("v1.lsp.config.lua"), -- lua/lsp/config/lua.lua
    bashls = require("v1.lsp.config.bash"),
    pyright = require("v1.lsp.config.pyright"),
    html = require("v1.lsp.config.html"),
    cssls = require("v1.lsp.config.css"),
    emmet_ls = require("v1.lsp.config.emmet"),
    jsonls = require("v1.lsp.config.json"),
    yamlls = require("v1.lsp.config.yamlls"),
    dockerls = require("v1.lsp.config.docker"),
    tailwindcss = require("v1.lsp.config.tailwindcss"),
    rust_analyzer = require("v1.lsp.config.rust"),
    taplo = require("v1.lsp.config.taplo"), -- toml
    gopls = require("v1.lsp.config.gopls"),
    clangd = require("v1.lsp.config.clangd"),
    cmake = require("v1.lsp.config.cmake"),
}

-- enabled lsp server map
-- key : lspconfig server name
-- value: lsp config file
local enabled_lsps = {}
-- linter and formatter ensure list
local tools = {}

if cfg.frontend.enable then
    -- frontend need several lsp servers
    for _, value in pairs(cfg.frontend.lsp) do
        if all_lsps[value] then
            enabled_lsps[value] = all_lsps[value]
        end
    end
    if cfg.frontend.linter == "eslint_d" or cfg.frontend.formatter == "eslint_d" then
        table.insert(tools, "eslint_d")
    end
    if cfg.frontend.formatter == "prettier" then
        table.insert(tools, "prettier")
    end
end

for _, lang in pairs(cfg.singular) do
    if lang.enable and all_lsps[lang.lsp] then
        enabled_lsps[lang.lsp] = all_lsps[lang.lsp]
    end
    if lang.formatter then
        table.insert(tools, lang.formatter)
    end
    if lang.linter then
        table.insert(tools, lang.linter)
    end
end

return enabled_lsps, tools
