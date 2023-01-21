local cfg = require("v1.config").plugin.bufferline

-- Vanilla keybindings
vim.keymap.set("n", cfg.keys.prev, ":BufferLineCyclePrev<CR>")
vim.keymap.set("n", cfg.keys.next, ":BufferLineCycleNext<CR>")
-- "moll/vim-bbye" keybindings
vim.keymap.set("n", cfg.keys.close, ":Bdelete!<CR>")
vim.keymap.set("n", cfg.keys.close_left, ":BufferLineCloseLeft<CR>")
vim.keymap.set("n", cfg.keys.close_right, ":BufferLineCloseRight<CR>")
vim.keymap.set("n", cfg.keys.close_others, ":BufferLineCloseRight<CR>:BufferLineCloseLeft<CR>")
vim.keymap.set("n", cfg.keys.close_pick, ":BufferLinePickClose<CR>")

require("bufferline").setup({
  options = {
    close_command = "Bdelete! %d",
    right_mouse_command = "Bdelete! %d",
    offsets = {
      {
        filetype = "NvimTree",
        text = "File Explorer",
        highlight = "Directory",
        text_align = "left",
      },
    },
    ---@diagnostic disable-next-line: assign-type-mismatch
    diagnostics = "nvim_lsp",
    ---@diagnostic disable-next-line: unused-local
    diagnostics_indicator = function(count, level, diagnostics_dict, context)
      local s = " "
      for e, n in pairs(diagnostics_dict) do
        local sym = e == "error" and " " or (e == "warning" and " " or "")
        s = s .. n .. sym
      end
      return s
    end,
  },
})
