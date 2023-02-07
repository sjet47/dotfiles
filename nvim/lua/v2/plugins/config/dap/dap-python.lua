-- Python and methods to debug individual test methods or classes
---@see https://github.com/mfussenegger/nvim-dap-python
return {
    "mfussenegger/nvim-dap-python",
    requires = { "mfussenegger/nvim-dap" },
    config = function()
        require("v2.dap.python")
    end
}
