return {
    setup = function(enable_plugin)
        require("v1.basic")
        if enable_plugin then
            -- Load plugins
            require("v1.plugins")
            require("v1.lsp")
        end
    end
}
