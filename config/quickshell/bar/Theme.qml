//
// 状态栏配色 / 字号 / 间距的唯一出处。
//
// 数值全部来自迁移前的 waybar/style.css —— 迁移要求 1:1 复刻,所以这里的注释标了每个值
// 对应原来哪条 CSS,改之前先想清楚是不是真要跟 waybar 不一样了。
//
// 注意 Qt 的八位色是 **AARRGGBB**(README 坑 2),CSS 的 rgba(r,g,b,a) 要手工换算:
//   rgba(28,28,30,0.78)  →  alpha 0.78*255 = 199 = 0xc7  →  #c71c1c1e
//
pragma Singleton

import QtQuick
import Quickshell

Singleton {
    // ---- 颜色(= style.css 顶部的 @define-color) ----
    readonly property color bg:         "#c71c1c1e"   // @background  rgba(28,28,30,.78)
    readonly property color bgHover:    "#14ffffff"   // @background-hover  rgba(255,255,255,.08)
    readonly property color bgActive:   "#24ffffff"   // @background-active rgba(255,255,255,.14)
    readonly property color separator:  "#1affffff"   // @separator   rgba(255,255,255,.10)
    readonly property color border:     "#12ffffff"   // @border      rgba(255,255,255,.07)
    readonly property color fg:         "#f5f5f7"     // @foreground
    readonly property color muted:      "#98989d"     // @muted
    readonly property color warning:    "#ffd60a"     // @warning
    readonly property color critical:   "#ff453a"     // @critical

    // tooltip 比状态栏更实(rgba(28,28,30,.95)),因为它浮在任意窗口上而不是只压桌面
    readonly property color tooltipBg:     "#f21c1c1e"
    readonly property color tooltipBorder: "#1affffff"

    // ---- 字体 ----
    // style.css 的 font-family 是一整串 fallback 链,Qt 这边分成两个用途写:
    // 正文交给 Noto Sans(CJK 由 fontconfig 自己 fallback),Nerd Font 图标必须显式指定,
    // 否则会掉进 Noto 的缺字框。
    readonly property string font:     "Noto Sans"
    readonly property string iconFont: "JetBrainsMono Nerd Font"
    // **这一项刻意不等于 waybar**:style.css 是 16px,实测 Qt 侧 16px 与 waybar 的渲染
    // 结果几乎逐像素一致(时钟整串 336 vs 334,数字 cap height 18 vs 18,墨覆盖量差 1.2%),
    // 但用户看下来还是偏小,自己选定了 18。迁移的 1:1 目标到此为止 —— 这是审美决定,不是缺陷。
    // 副屏(1440 逻辑宽)在 18 下放不下完整股价,会按 Bar.qml 的夹取逻辑截断,不会重叠。
    readonly property int    fontSize: 18            // style.css 原值是 16px

    // 文字渲染方式:两项都要,而且都是实测定下来的(README 坑 33)。
    //   NativeRendering        —— Qt 默认的 QtRendering 在 scale 1.5 下有彩色条纹
    //   PreferVerticalHinting  —— 对应 fontconfig 的 hintslight(`fc-match --verbose` 里
    //                             hintstyle: 1),GTK 走的就是这条。用 PreferFullHinting
    //                             会把数字的 cap height 从 18px 往下 snap 成 17px,
    //                             字母却不受影响 —— 表现为"数字看着矮一点"
    readonly property int hinting: Font.PreferVerticalHinting

    // **别想着用 `font.families` 去复刻 CSS 的 fallback 链** —— quickshell 的 QML 引擎里
    // 这个属性不存在(连字面量数组都报 `Cannot assign to non-existent property "families"`,
    // Qt 6.11 下实测)。只能 `font.family` 给单个字体,缺字交给 fontconfig 自己 fallback。
    // Nerd Font 的图标在私有区,fontconfig 的 fallback 对私有区不可靠,所以**图标和文本
    // 要拆成两个 Text**:图标那段显式指定 iconFont,文本那段用 font。

    // ---- 几何(= config.jsonc 的 height/margin + style.css 的 radius) ----
    // **31 而不是 28**:config.jsonc 写的 `height: 28` 是 GTK 控件高度,style.css 又给
    // window#waybar 加了 1px 边框,实测 waybar 的 layer surface 是 31 逻辑像素高
    // (`hyprctl layers` 可查,锁屏时也能查)。照 28 写会矮 3px,独占区也跟着少 3px,
    // 窗口布局会比迁移前高一点点。
    readonly property int barHeight:   28
    readonly property int pillHeight:  28            // 工作区按钮:28 的内容区减去 margin 4px 上下
    readonly property int marginTop:   4
    readonly property int marginSide:  8
    readonly property int radius:      14
    readonly property int edgePad:     10            // .modules-left/right 的 margin
    readonly property int itemMargin:  8             // 通用模块 margin: 0 8px
    readonly property int itemPad:     2             // 通用模块 padding: 0 2px
    readonly property int groupGap:    14            // #tray/#cpu/#clock 的 margin+padding-left
}
