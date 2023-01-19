local null_ls = require("null-ls")

local cfg = require("v1.config").lsp
local formatting = null_ls.builtins.formatting
local diagnostics = null_ls.builtins.diagnostics
local code_actions = null_ls.builtins.code_actions
local fmters = {
    stylua = formatting.stylua,
    shfmt = formatting.shfmt,
    gofmt = formatting.gofmt,
    rustfmt = formatting.rustfmt,
    eslint_d = formatting.eslint_d,
    prettier = formatting.prettier.with({
        filetypes = {
            "javascript",
            "javascriptreact",
            "typescript",
            "typescriptreact",
            "vue",
            "css",
            "scss",
            "less",
            "html",
            "json",
            "yaml",
            "toml",
            "markdown",
        },
        timeout = 10000,
        prefer_local = "node_modules/.bin",
    }),
    black = formatting.black.with({ extra_args = { "--fast" } }),
}
local linters = {
    golangci_lint = diagnostics.golangci_lint,
    eslint_d = diagnostics.eslint_d,
}
local actions = {
    eslint_d = code_actions.eslint_d,
    gitsigns = code_actions.gitsigns,
}

local sources = {}
if cfg.frontend.enable then
    local formatter = fmters[cfg.frontend.formatter]
    local linter = linters[cfg.frontend.linter]
    local ca = actions[cfg.frontend.code_actions]
    if formatter then
        table.insert(sources, formatter)
    end
    if linter then
        table.insert(sources, linter)
    end
    if ca then
        table.insert(sources, ca)
    end
end

for name, lang in pairs(cfg.singular) do
    if lang.enable then
        if fmters[lang.formatter] then
            if lang.formatter == "prettier" then
                table.insert(sources, formatting.prettier.with({
                    filetypes = { name },
                }))
            else
                table.insert(sources, fmters[lang.formatter])
            end
        end
        if linters[lang.linter] then
            table.insert(sources, linters[lang.linter])
        end
    end
end

table.insert(sources, code_actions.gitsigns)

return sources