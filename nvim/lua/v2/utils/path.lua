local M = {}

M.data = function()
  return vim.fn.stdpath("data")
end

M.config = function()
  return vim.fn.stdpath("config")
end

M.cache = function()
  return vim.fn.stdpath("cache")
end

M.join = function(...)
  local path_sep = vim.loop.os_uname().version:match("Windows") and "\\" or "/"
  return table.concat({ ... }, path_sep)
end

return M
