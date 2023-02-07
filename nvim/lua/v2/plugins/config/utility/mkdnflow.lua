-- For fluent navigation of documents and notebooks (AKA "wikis") written in markdown
---@see https://github.com/jakewvincent/mkdnflow.nvim
local cfg = require("v2.config").mkdnflow
return {
  "jakewvincent/mkdnflow.nvim",
  config = function()
    local mkdnflowGroup = vim.api.nvim_create_augroup("mkdnflowGroup", {
      clear = true,
    })
    vim.api.nvim_create_autocmd("FileType", {
      group = mkdnflowGroup,
      pattern = { "markdown", "md", "mdx" },
      callback = function()
        local opts = { buffer = vim.api.nvim_get_current_buf() }
        vim.keymap.set("n", cfg.mkdnflow.next_link, "<cmd>MkdnNextLink<CR>", opts)
        vim.keymap.set("n", cfg.mkdnflow.prev_link, "<cmd>MkdnPrevLink<CR>", opts)
        vim.keymap.set("n", cfg.mkdnflow.prev_heading, "<cmd>MkdnPrevHeading<CR>", opts)
        vim.keymap.set("n", cfg.mkdnflow.next_heading, "<cmd>MkdnNextHeading<CR>", opts)
        vim.keymap.set("n", cfg.mkdnflow.go_back, "<cmd>MkdnGoBack<CR>", opts)
        vim.keymap.set("n", cfg.mkdnflow.follow_link, "<cmd>MkdnFollowLink<CR>", opts)
        vim.keymap.set("n", cfg.mkdnflow.toggle_item, "<cmd>MkdnToggleToDo<CR>", opts)
        vim.keymap.set({ "n", "x" }, cfg.mkdnflow.follow_link, "<cmd>MkdnFollowLink<CR>", opts)
      end,
    })

    require("mkdnflow").setup({
      modules = {
        maps = false,
      },
      filetypes = { md = true, mdx = true, markdown = true },
      links = {
        style = "markdown",
        implicit_extension = nil,
        transform_implicit = false,
        transform_explicit = function(text)
          text = text:gsub(" ", "-")
          text = text:lower()
          text = os.date("%Y-%m-%d-") .. text
          return text
        end,
      },
    })
  end
}
