# dotfiles

Arch Linux + Hyprland 的个人配置仓库。

## 视觉改动要截图自验证

改完 waybar 样式、Hyprland 外观（gaps/border/blur/动画）、wlogout 布局这类**视觉相关配置后，截图确认实际效果**，不要只凭代码判断对错：

```bash
~/.config/hypr/scripts/screenshot.sh fullscreen save   # 焦点显示器整屏
~/.config/hypr/scripts/screenshot.sh active save       # 当前活动窗口
```

两条都不需要交互，直接把 PNG 路径打到 stdout，Read 该路径即可查看图片。加了 `save` 就不会碰剪贴板、不弹通知，也不会打断用户手上正在进行的框选。

几点注意：

- waybar、mako 通知属于 layer-shell surface，不是窗口，只有 `fullscreen` 能截到。
- `active` 截的是当前焦点窗口——从终端里调用时焦点多半在终端上，先确认目标窗口真的处于焦点。
- 不带 `save` 的调用（`screenshot.sh`、`region`、`window`）是给人用的交互流程：会拉起框选、写剪贴板、弹标注通知，不要在自动化里用。
