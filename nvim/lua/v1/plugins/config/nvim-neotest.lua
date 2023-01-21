local neotest = require("neotest")
local cfg = require("v1.config").plugin.neotest
local lsp = require("v1.config").lsp.singular

-- vim.keymap.set("n", cfg.toggle, neotest.summary.toggle())
-- vim.keymap.set("n", cfg.run, neotest.run.run())
-- vim.keymap.set("n", cfg.run_dap, neotest.run.run({ strategy = "dap" }))
-- vim.keymap.set("n", cfg.run_file, neotest.run.run(vim.fn.expand("%")))
-- vim.keymap.set("n", cfg.run_stop, neotest.run.stop())
-- vim.keymap.set("n", cfg.output_open, neotest.output.open({ enter = true }))

local adapters = {}
if lsp.golang.enable then
  table.insert(
    adapters,
    require("neotest-go")({
      experimental = {
        test_table = true,
      },
      args = { "-count=1", "-timeout=60s" },
    })
  )
end

-- get neotest namespace (api call creates or returns namespace)
local neotest_ns = vim.api.nvim_create_namespace("neotest")
vim.diagnostic.config({
  virtual_text = {
    format = function(diagnostic)
      local message = diagnostic.message:gsub("\n", " "):gsub("\t", " "):gsub("%s+", " "):gsub("^%s+", "")
      return message
    end,
  },
}, neotest_ns)

require("neotest").setup({
  adapters = adapters,

  summary = {
    animated = true,
    enabled = true,
    expand_errors = true,
    follow = true,
    mappings = {
      expand = { "o", "<2-LeftMouse>" },
      jumpto = "<CR>",
      output = "O",
      short = "s",
    },
  },

  icons = {
    passed = "",
    failed = "",
    running = "",
    running_animated = { "▫", "▪" },
    skipped = "-",
    unknown = "",
  },
  diagnostic = {
    enabled = true,
  },
  status = {
    signs = false,
    virtual_text = true,
  },
})
