-- ************************************************************
-- *                           Jump                           *
-- ************************************************************

-- Leader key
-- vim.g.mapleader = " "

-- Select all
vim.keymap.set("", "<C-a>", "gg0vG$")

-- Go to head of line
vim.keymap.set("", "<C-h>", "^")

-- Go to tail of line
vim.keymap.set("", "<C-l>", "$")

-- Save
vim.keymap.set("n", "<C-s>", "<cmd>:w<cr>")

-- Back quote
vim.keymap.set("n", "``", "ciw``<Esc>hp")
vim.keymap.set("v", "``", "s``<Esc>hp")

-- Use jj as Esc
vim.keymap.set("i", "jj", "<Esc>")
