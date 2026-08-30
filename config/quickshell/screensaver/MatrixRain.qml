//
// Matrix 雨本体。屏保的画面部分,不关心什么时候该出现。
//
// **整屏一个 ShaderEffect**,雨全在 GPU 里算:每个像素自己判断落在哪个格子、那一格该多亮、
// 该显示哪个字形。每列的速度/亮尾长度/明暗/相位由**列号 hash 出来**,不从 CPU 传任何
// per-column 数据;CPU 每帧只更新一个 time。逻辑见 matrix.frag。
//
// 为什么不是 QML 逐格更新(上一版):那版每个格子一个 Text,亮点每跨一格就要用 JS 改窗口内
// 十几个格子的属性,再让 Qt 重建场景图节点。4K 双屏实测 48~62fps 且**肉眼可见地忽快忽慢**
// —— JS 执行、GC、Timer 调度的抖动全被看得见。而且密度是花钱的:格子每加密一档就多几千个
// Text 对象,14x19 只能跑到 23fps。shader 版每像素开销与格子大小无关,密度免费。
//
// 另外两件只有 shader 版做得到的事:
//   - **CRT 余晖**。亮度是 d(到亮点的距离)的连续函数,点亮有爬升段、熄灭有衰减段,
//     每一格都是"亮起来再暗下去"。逐格更新版的 opacity 是一步到位的,只能瞬间点亮。
//   - 速度可以随便提。逐格更新版的速度上限被帧率卡死(一帧跨多格就又变回一顿一顿)。
//
// 字符仍然是钉在网格上不动的 —— 那是 matrix 雨的本质(对照 cmatrix:格子里的字符不动,
// 是亮点逐个把它们点亮再让它们暗下去),不是一条字符流整体平移。
//
pragma ComponentBehavior: Bound

import QtQuick

Item {
    id: rain

    // ---- 密度 / 尺寸 ----
    // 格子是**正方形**,因为用的是全角片假名(见 glyphAt):Unifont 里全角是 16x16 点阵,
    // 半角只有 8x16 —— 宽度只有 8 个点,笔画稍多的假名(ﾈ ﾂ ﾔ 之类)就糊成一团。
    //
    // 格子是**半角比例**(1:2)。用半角假名就不必把格子撑成正方形,同样宽度能多塞一倍的列。
    //
    // cellH 必须是 glyphPixels 的**整数倍**:图集单元被 nearest 放大到格子大小,
    // 非整数倍时有的源像素占 2 个屏幕像素、有的占 3 个,像素块宽窄不匀 —— 那就是"糊"。
    // 这里 32 / 16 = 2 倍。
    property int cellW: 16
    property int cellH: 32

    // 相邻列的亮点至少要错开几行。0 = 不管。
    // 约束的是**并列的亮点**,不是"同时有雨" —— 相邻列尽管一起下,只要上下错开就不难看。
    // 调大 = 错得更开,但让位变多、整屏变稀。
    property real headGap: 3
    // 亮度低于这个值的尾梢允许和邻居重叠 —— 太暗了,压在一起也看不出来,放它过去能换回
    // 不少密度。0 = 整条亮尾都不许重叠(最严,但整屏会很稀)。亮度范围见 dimMin/dimMax。
    property real overlapBelow: 0.5

    // 一趟雨走完之后空几格再开下一趟。0 = 一趟接一趟,调大则列上出现空窗,整屏更稀疏。
    // 这是"时间上的密度",上面 cellW/colStride 是"空间上的",是两回事。
    property real gapMin: 0
    property real gapMax: 3

    // ---- 字形 ----
    // 字体**必须覆盖用到的字符**,否则整屏豆腐块 —— 而且 fontconfig 会悄悄 fallback,
    // 不报任何错。查:`fc-list ':charset=30a2' family | grep -i <字体>`
    // (`:charset=` 要作为**查询条件**放在 pattern 位置。写成 `fc-list "字体" :charset=30a2`
    //  是把它当成了输出字段,那样永远有输出,等于没查 —— 这里踩过:当初据此认定
    //  Maple Mono NF CN 覆盖片假名,其实它根本没有,一直在 fallback 到 Noto。)
    //
    // **注意 Maple Mono NF CN 并不覆盖片假名**,假名会 fontconfig fallback 到
    // Noto Sans Mono CJK —— 也就是数字是 Maple、假名是 Noto,两种字体混着。
    // 这是明知故犯(用户选的字形观感),不是没查。想让整套字形统一就换成
    // "Noto Sans Mono CJK SC";想要真点阵换 "Unifont" 并把 glyphPixels 设成 16。
    property string fontFamily: "Maple Mono NF CN"

    // 图集单元的高(逻辑像素)。**这是像素粗细旋钮**:字形以这个分辨率烤进图集,
    // 再被 nearest 放大 cellH/glyphPixels 倍 —— 调小 = 每个像素块更大、更颗粒。
    // 必须能整除 cellH。
    //
    // **不想要像素化**:把它设成 cellH(1:1,不放大)再把 sharpen 设成 0,
    // 上面的 smooth 和下面的 renderType 会自动跟着切到平滑那一档。
    property int glyphPixels: 16

    // 字号占图集单元的比例。点阵字体要 1.0(缩一下点阵网格就错位了),矢量字体可用 0.8~0.95
    property real fontScale: 0.8

    // 字形 alpha 的二值化阈值,消掉抗锯齿灰边 —— 点阵要的是硬边。
    // 设 0 关掉(用矢量字体、想要平滑描边时)
    property real sharpen: 0

    // ---- CRT 味道 ----
    // 荧光:字形周围洇出来的一圈柔光(磷光体被打亮时的扩散)。0 = 关。
    // 核心字形始终是硬边的,光晕只负责氛围,所以不会把点阵糊掉。
    property real glow: 0.55
    property real glowRadius: 0.22     // 扩散半径,格子的比例
    // 扫描线深度。0 = 关;0.15~0.3 比较像老显示器,再大就闪得难受
    property real scanline: 0.18

    // ---- 速度 ----
    // 单位是**格/秒**,不是像素/秒 —— 所以横竖两块屏的视觉移动速度一致,
    // 只是竖屏更高、走完一趟更久。shader 版速度不再受帧率约束,想多快都行。
    property real minSpeed: 16
    property real maxSpeed: 28

    // ---- 亮尾与层次 ----
    // 亮尾长度(格)。跨度要大 —— 等长会让所有尾巴末端连成一条整齐的横线,一眼假
    property real minLen: 20
    property real maxLen: 50
    // 每条流的整体明暗,远近层次全靠它。下限太低会整屏发灰,
    // 观感上的"密度不够"多半是亮度问题而不是列数问题
    property real dimMin: 0.8
    property real dimMax: 1.0

    // ---- 颜色 ----
    property color color: "#00ff41"    // 经典 matrix 绿
    property color headColor: "#d7ffd7"

    readonly property int cols: Math.max(1, Math.ceil(rain.width / rain.cellW))
    readonly property int rows: Math.max(1, Math.ceil(rain.height / rain.cellH))

    // 半角片假名 U+FF71..FF9D(45 个)+ 数字。
    //
    // 半角区**天然只有清音** —— 浊音在半角里要靠组合符号 ﾞﾟ 拼,所以不像全角区
    // (U+30A1..30F6)那样一取一整段就把 ゾ ヅ ボ ジ 和小写假名全带进来,点又多又碎。
    //
    // digitWeight 是**日文/数字的比重旋钮**:数字整组重复几次,出现概率就是假名的几分之几。
    // 45 个假名配 3 组数字 ≈ 6:4。嫌日文多就调大它。
    property int digitWeight: 3
    readonly property string glyphs: {
        let out = "";
        for (let c = 0xff71; c <= 0xff9d; c++) out += String.fromCharCode(c);
        for (let k = 0; k < rain.digitWeight; k++) out += "0123456789";
        return out;
    }
    readonly property int glyphCount: rain.glyphs.length
    function glyphAt(i: int): string {
        return rain.glyphs.charAt(i);
    }

    // 字形图集:66 个字符排成一横条,交给 shader 采样。
    // 单元格比例必须跟着 cellW:cellH 走,否则改了格子形状字形会被拉伸
    readonly property int atlasH: rain.glyphPixels
    readonly property int atlasW: Math.max(1, Math.round(rain.atlasH * rain.cellW / rain.cellH))

    Item {
        id: glyphStrip
        width: rain.glyphCount * rain.atlasW
        height: rain.atlasH

        Row {
            Repeater {
                model: rain.glyphCount

                Text {
                    required property int index
                    width: rain.atlasW
                    height: rain.atlasH
                    text: rain.glyphAt(this.index)
                    // 图集只存字形形状,颜色由 shader 给 —— 这里必须是纯白
                    color: "white"
                    font.family: rain.fontFamily
                    // 要硬边(sharpen>0)时用 NativeRendering,走 FreeType 直接栅格化;
                    // 不二值化时用默认的 distance field,边缘更平滑。跟着 sharpen 自动切换。
                    renderType: rain.sharpen > 0 ? Text.NativeRendering : Text.QtRendering
                    font.pixelSize: Math.round(rain.atlasH * rain.fontScale)
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
            }
        }
    }

    ShaderEffectSource {
        id: glyphAtlas
        sourceItem: glyphStrip
        hideSource: true
        // 很小的一张纹理,每帧重画一次的开销可以忽略。用 live: false 反而要自己
        // 挑时机 scheduleUpdate(),字体是异步加载的,挑早了会烤进一张空图集。
        live: true
        // 图集比格子小(=正在做像素化)时必须关掉线性过滤,nearest 才出得来像素块;
        // 1:1 或更高时反而要开,否则边缘会有锯齿。跟着 glyphPixels 自动切换。
        smooth: rain.glyphPixels >= rain.cellH
    }

    // 每帧推进的时钟。FrameAnimation(Qt 6.4+)跟着渲染帧走,比 Timer 准。
    FrameAnimation {
        id: clock
        running: true
    }

    ShaderEffect {
        anchors.fill: parent
        fragmentShader: Qt.resolvedUrl("matrix.frag.qsb")

        // 属性按**名字**匹配 matrix.frag 里 uniform block 的成员,改名要两边一起改
        property variant atlas: glyphAtlas
        property real time: clock.elapsedTime
        property real cols: rain.cols
        property real rows: rain.rows
        property real glyphCount: rain.glyphCount
        property real minSpeed: rain.minSpeed
        property real maxSpeed: rain.maxSpeed
        property real minLen: rain.minLen
        property real maxLen: rain.maxLen
        property real dimMin: rain.dimMin
        property real dimMax: rain.dimMax
        property real gapMin: rain.gapMin
        property real gapMax: rain.gapMax
        property real sharpen: rain.sharpen
        property real headGap: rain.headGap
        property real overlapBelow: rain.overlapBelow
        property real glow: rain.glow
        property real glowRadius: rain.glowRadius
        property real scanline: rain.scanline
        property color baseColor: rain.color
        property color headColor: rain.headColor
    }
}
