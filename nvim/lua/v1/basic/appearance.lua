-- Display absolute line number
vim.o.number = true
-- Display relative line number for short jump
vim.o.relativenumber = true

-- Left sign column(not known what it does currently)
-- It place a placeholder at the left most column
vim.o.signcolumn = "yes:1"

-- Highlight current cursor row/column
vim.o.cursorline = true
vim.o.cursorcolumn = true

-- Set an 80 color column border
vim.o.colorcolumn = "80"

-- Number of columns a tab occupied
vim.o.tabstop = 4

-- Show Matching
vim.o.showmatch = true

-- Highlight search result
vim.o.hlsearch = true

-- Command-line height
vim.o.cmdheight = 1

-- Dont wrap code
vim.o.wrap = false
vim.o.whichwrap = "<,>,[,]"

-- Display invisible characters
vim.o.list = false
vim.o.listchars = "space:·,tab:··"

-- Display current edit mode(i.e. INSERT), (disable when using lualine plugin)
vim.o.showmode = true

-- Always display tabs(opened buffers) at the top line
vim.o.showtabline = 2

-- How many line should around the cursor at least
vim.o.scrolloff = 8

-- How many column should around the cursor at least
vim.o.sidescrolloff = 8

-- Use terminal color as neovim color
vim.o.termguicolors = false
