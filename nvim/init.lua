if vim.g.vscode then
	-- VSCode extension
	require("v1").setup(false)
else
	-- ordinary Neovim
	require("v1").setup(true)
end

