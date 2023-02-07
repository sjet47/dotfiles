-- Standalone UI for nvim-lsp progress. Eye candy for the impatient
---@see https://github.com/j-hui/fidget.nvim
return {
  "j-hui/fidget.nvim",
  config = function()
    require("fidget").setup({
      text = {
        spinner = "dots_pulse", -- animation shown when tasks are ongoing
        done = "✔", -- character shown when all tasks are complete
        commenced = "Started", -- message shown when task starts
        completed = "Completed", -- message shown when task completes
      },
      sources = {
        ["null-ls"] = {
          ignore = true,
        },
      },
    })
  end
}
