require("basic")

-- Skip plugins if running with vscode
if vim.g.vscode then
	return
end

-- Set lazy.nvim path: $HOME/.config/nvim/lazy/lazy.nvim
local lazypath = vim.fn.stdpath("config") .. "/lazy/lazy.nvim"
vim.opt.rtp:prepend(lazypath)

-- Load plugins
require("lazy").setup("plugins", require("config"))

-- Set colorscheme
vim.cmd("colorscheme onedark")
