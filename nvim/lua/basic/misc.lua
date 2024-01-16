-- Use UTF-8 Encoding
vim.g.encoding = "UTF-8"
vim.o.fileencoding = "utf-8"

-- The length of time Vim waits after you stop typing before it triggers the plugin
vim.o.updatetime = 500

-- Duration in ms of waiting for a mapped sequence to complete
vim.o.timeoutlen = 200

-- Disable netrw at the very start of your init.lua, use nvim-tree instead
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1
