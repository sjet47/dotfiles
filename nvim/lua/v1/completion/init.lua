-- ************************************************************
-- *                        Appearance                        *
-- ************************************************************

-- Completion menu
vim.g.completeopt = "menu,menuone,noselect,noinsert"

-- popup menu 10 items in max
vim.o.pumheight = 10

-- ************************************************************
-- *                          Option                          *
-- ************************************************************

-- Enhance command-line completion
vim.o.wildmenu = true

-- Dont' pass messages to |ins-completin menu|
vim.o.shortmess = vim.o.shortmess .. "c"
