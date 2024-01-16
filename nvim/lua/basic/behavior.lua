-- Enable mouse click
vim.o.mouse = "a"

-- Paste with middle-click
-- vim.o.mouse = "v"

-- ignore case except uppercase
vim.o.ignorecase = true
vim.o.smartcase = true

-- Incremental search
vim.o.incsearch = true

-- See multiple spaces as tabstops so <BS> does the right thing
vim.o.softtabstop = 2

-- Convert tab to space
vim.o.expandtab = false

-- Width of shift(<< and >>)
vim.o.shiftwidth = 2

-- Round indent to a multiple of 'shiftwidth', i.e. 3 => 4
vim.o.shiftround = true

-- Indent a new line the same amount as the line just typed(including copy)
vim.o.autoindent = true
vim.o.smartindent = true

-- New vertical-split pane focus on below
vim.o.splitbelow = true

-- New horizen-split pane focus on right
vim.o.splitright = true

-- Use register '+' as system clipboard
vim.o.clipboard = "unnamedplus"

-- Speed up scrolling
-- vim.o.ttyfast = true

-- Allow open multiple buffers(files) at the same time
vim.o.hidden = true

-- Disable backup and swap file for privacy reason
vim.o.backup = false
vim.o.writebackup = false
vim.o.swapfile = false

-- Auto reload file when edited outside
vim.o.autoread = true


-- Disable vi-compatible to make vim behave in a more useful way
vim.o.compatible = false