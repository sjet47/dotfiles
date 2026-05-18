-- 显示器配置
-- 文档: https://wiki.hypr.land/Configuring/Basics/Monitors/
--
-- 具体每台显示器的规则放在 local/init.lua(机器相关,不入库)。
-- 这里只留一条 fallback:任何未被显式规则匹配的显示器,自动放到右侧、用首选分辨率。

hl.monitor({
  output   = "",
  mode     = "preferred",
  position = "auto",
  scale    = 1,
})
