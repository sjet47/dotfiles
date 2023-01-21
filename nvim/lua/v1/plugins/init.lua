local cfg = require("v1.config").plugin.packer
local packer_path = vim.fn.stdpath('data') .. cfg.path

-- Make sure packer.nvim is installed
local function install_packer()
    if vim.fn.empty(vim.fn.glob(packer_path)) > 0 then
        vim.notify("packer.nvim not found")
        vim.notify("installing packer.nvim")
        vim.fn.system({
            "git", "clone", "--depth", "1",
            cfg.mirror .. cfg.repo_uri,
            packer_path,
        })
        vim.cmd.packadd("packer.nvim")
        vim.notify("packer.nvim install completed")
        return true
    end
    return false
end

local bootstrap = install_packer()

local packer = require("packer")
packer.reset()
packer.init({
    ---@see https://github.com/wbthomason/packer.nvim#custom-initialization
    max_jobs = cfg.max_jobs,
    git = {
        clone_timeout = cfg.clone_timeout,
        default_url_format = cfg.mirror .. "%s",
    },
    display = {
        open_fn = function()
            return require("packer.util").float({ border = "rounded" })
        end,
    },
})

function usePlugins(use, plugins)
    for _, plugin in ipairs(plugins) do
        use(plugin)
    end
end

-- Start packer
require("packer").startup(function(use)
    local plugins = require("v1.plugins.config")

    usePlugins(use, plugins.dependence)
    usePlugins(use, plugins.appearance)
    usePlugins(use, plugins.utility)
    usePlugins(use, plugins.coding)

    if bootstrap then
        packer.sync()
    end
end)

if bootstrap then
    packer.sync()
end

return {
    sync = packer.sync,
}
