-- 跨模块共享的变量。其他模块通过 require("modules.vars") 取用。
-- (Lua 每个 require 是独立 scope,共享值需经模块 return 传递,不能靠全局 $var)

return {
  terminal    = "kitty",
  fileManager = "dolphin",
  menu        = "vicinae toggle",
  mainMod     = "SUPER", -- "Windows" 键作为主修饰键
}
