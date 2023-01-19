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
local status_ok, packer = pcall(require, "packer")
if not status_ok then
    vim.notify("require packer.nvim failed, check " .. packer_path)
    return
end


-- Load plugin list
package.loaded["v1.plugins"] = nil
local plugins = require("v1.plugins")
if cfg.lock then
    local snapshot_path = vim.fn.stdpath("config") .. "/snapshots.json"
    local snapshot = vim.fn.json_decode(vim.fn.readfile(snapshot_path))
    for _, plugin in ipairs(plugins) do
        local short_name, _ = require("packer.util").get_plugin_short_name(plugin)
        if snapshot and snapshot[short_name] and snapshot[short_name].commit then
            plugin.commit = snapshot[short_name].commit
        end
    end
end


-- Start packer
packer.reset()
packer.startup({
    function(use)
        for _, plugin in ipairs(plugins) do
            use(plugin)
        end

        if bootstrap then
            packer.sync()
        end
    end,
    config = {
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
    }
})

return {
    sync = packer.sync
}
