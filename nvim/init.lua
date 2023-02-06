if vim.g.vscode then
	-- VSCode extension
	require("v1").setup(false)
else
	-- Neovim with plugins
	require("v1").setup(true)
end

