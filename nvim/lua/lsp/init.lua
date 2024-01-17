---@type table<lang: string, lsp_config>
return {
    go = require("lsp.go"),
    cpp = require("lsp.cpp"),
    rust = require("lsp.rust"),
}
