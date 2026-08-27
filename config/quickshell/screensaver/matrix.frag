// Matrix 雨 —— 整屏一个 ShaderEffect,每像素自己算属于哪个格子、该多亮、该显示哪个字形。
//
// 编译(改完必须重新编译,QML 加载的是 .qsb 不是这个文件):
//   /usr/lib/qt6/bin/qsb --qt6 -o matrix.frag.qsb matrix.frag
//
// uniform block 的成员按**名字**匹配 QML 里的同名属性(改名要两边一起改)。
// 布局是 std140,但 offset 由编译器算好写进 .qsb 的 reflection,Qt 照着绑 —— 所以增删成员
// 是安全的,不用自己数对齐。想看实际布局:`qsb --dump matrix.frag.qsb`。
#version 440

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    float time;
    float cols;
    float rows;
    float glyphCount;
    float minSpeed;      // 格/秒
    float maxSpeed;
    float minLen;        // 亮尾长度(格)
    float maxLen;
    float dimMin;
    float dimMax;
    float gapMin;        // 空档:亮尾走完之后再等几格才开下一趟
    float gapMax;
    float sharpen;       // >0 时把字形 alpha 按此阈值二值化,消掉抗锯齿灰边
    float headGap;       // 相邻列的亮尾至少要错开几行(0 = 不管)
    float overlapBelow;  // 亮度低于它的那截尾巴允许重叠(0 = 整条都算)
    float glow;          // 字形周围的荧光强度(0 = 关)
    float glowRadius;    // 荧光扩散半径(格子的比例)
    float scanline;      // 扫描线深度(0 = 关)
    vec4 baseColor;
    vec4 headColor;
};

layout(binding = 1) uniform sampler2D atlas;

float hash11(float p) {
    p = fract(p * 0.1031);
    p *= p + 33.33;
    p *= p + p;
    return fract(p);
}

float hash21(vec2 p) {
    vec3 p3 = fract(vec3(p.xyx) * 0.1031);
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.x + p3.y) * p3.z);
}

// 一列的固有参数,全部由列号 hash 出来 —— 不从 CPU 传任何 per-column 数据。
// x = 速度(格/秒), y = 亮尾长度(格), z = 明暗, w = 一趟的总长(含空档)
vec4 columnParams(float c) {
    float speed = mix(minSpeed, maxSpeed, hash11(c * 1.7 + 0.5));
    float len   = mix(minLen, maxLen, hash11(c * 3.1 + 5.0));
    float dim   = mix(dimMin, dimMax, hash11(c * 7.3 + 11.0));
    float gap   = mix(gapMin, gapMax, hash11(c * 5.9 + 31.0));
    // 一趟 = 亮尾从屏幕上方进来(len) + 穿过屏幕(rows) + 整条走出下方(len) + 空档(gap)
    return vec4(speed, len, dim, rows + len * 2.0 + gap);
}

// 这一列走过的总格数。trip = floor(t / cycle) 就是"第几趟"。
float columnTime(float c, vec4 pp) {
    return time * pp.x + hash11(c * 13.7 + 23.0) * pp.w;
}

// 亮点所在行,可为负(还没进屏幕)
float columnHead(float c, vec4 pp) {
    return mod(columnTime(c, pp), pp.w) - pp.y;
}

// 亮尾里"够亮、不许和邻居压在一起"的那一截有多长。
// 尾巴末梢暗到一定程度后压在一起也看不出来,放它过去能换回不少密度。
// 亮度 = pow(1 - d/len, 1.5) * dim,反解出亮度跌到 overlapBelow 时的 d 即可。
float brightLen(float len, float dim) {
    if (overlapBelow <= 0.0) return len;               // 0 = 整条都算
    float f = overlapBelow / max(dim, 1e-4);
    if (f >= 1.0) return 0.0;                          // 这条流整体就比阈值暗
    return len * (1.0 - pow(f, 2.0 / 3.0));
}

// 这一列在**指定时刻** tm 的亮尾:x = 亮点行号(可为负 = 还没进屏幕), y = 参与避让的长度
vec2 tailAt(float c, float tm) {
    vec4 pp = columnParams(c);
    float t = tm * pp.x + hash11(c * 13.7 + 23.0) * pp.w;
    return vec2(mod(t, pp.w) - pp.y, brightLen(pp.y, pp.z));
}

// 这一列当前这一趟"亮点刚进入屏幕"的那个时刻(全局秒)。
// 让位判断必须锚在这个时刻上,不能用当下 —— 见 main 里的说明。
float tripStartTime(float c, vec4 pp) {
    float t = columnTime(c, pp);                  // 单位:格
    float tStart = floor(t / pp.w) * pp.w + pp.y; // 这一趟里 head=0 对应的 t
    return (tStart - hash11(c * 13.7 + 23.0) * pp.w) / pp.x;
}

// 这一趟里会不会和邻居 cn 出现**并列的亮点**。沿整趟采样几个时刻判断 ——
// 只在趟开始时算一次、结果定死,中途绝不翻转(翻转就是闪现)。
//
// 为什么必须预判整趟而不是只看开跑那一刻:两列速度不同,下落途中相对位置一路漂移。
// 一趟好几秒、速度差能有十几格/秒,开跑时错开二十格的两条雨,半途照样追平。
bool willCollide(float cn, vec4 pp, float ts) {
    float T = pp.w / pp.x;                    // 一趟时长(秒)
    for (int i = 0; i <= 10; i++) {
        float t = ts + T * float(i) / 10.0;
        float hc = (t - ts) * pp.x;           // 自己的亮点行号,从 0 开始线性下落
        float lc = brightLen(pp.y, pp.z);     // 自己参与避让的那截
        if (hc - pp.y > rows) break;          // 整条亮尾都出屏了,后面不用看了
        vec2 nb = tailAt(cn, t);

        // 两条亮尾在屏幕内的行区间。比的是**够亮的那一截**(见 brightLen):
        // 渐暗的尾梢允许和邻居压在一起,反正看不出来。
        float aT = max(0.0, hc - lc), aB = min(rows, hc);
        float bT = max(0.0, nb.x - nb.y), bB = min(rows, nb.x);
        if (aB < aT || bB < bT) continue;     // 有一条此刻不在屏幕里
        // 各自向外扩 headGap 后仍相交 = 挨得太近
        if (aT - headGap <= bB && bT - headGap <= aB) return true;
    }
    return false;
}

// 采样字形图集。p 是格子内的归一化坐标,只收一丁点防浮点误差采到隔壁字形 ——
// **不能收多**:0.02/0.98 那种等于把字形压掉 4%,再 nearest 放大就是一排宽窄不一的像素柱。
float sampleGlyph(float gi, vec2 p) {
    vec2 q = clamp(p, vec2(0.001), vec2(0.999));
    return texture(atlas, vec2((gi + q.x) / glyphCount, q.y)).a;
}

void main() {
    vec2 grid = vec2(cols, rows);
    vec2 cell = floor(qt_TexCoord0 * grid);      // 这个像素落在哪个格子
    vec2 inCell = fract(qt_TexCoord0 * grid);    // 格子内部的 uv

    float c = cell.x;
    float r = cell.y;

    vec4 pp = columnParams(c);

    // 相邻两列**可以**同时下雨,不能出现的是**并列的亮点** —— 并排没问题,上下错开就行。
    //
    // 每列在自己这一趟开始的那一刻(此时自己的亮点在第 0 行),看左右邻居的亮点是不是也在
    // 附近;是就整趟不显示。两个关键点:
    //   1) **判断锚在趟开始时刻,不是"此刻"**。用此刻的话决定会在半途翻转:一列正下到
    //      一半、邻居一冲突它当场消失,冲突过去又当场出现在半屏中间 —— 表现就是
    //      "闪一下就没了"和"凭空急速下滑"。锚住之后整趟共用一个决定。
    //   2) 判断用邻居的**名义**位置(不管邻居自己是否也在让位),所以是纯函数、不会递归。
    //
    // 局限:只在开跑那一刻错开。两列速度不同,下落途中相对位置会漂移,偶尔还是会追平。
    // 想更严就加大 headGap,代价是让位变多、整屏变稀。
    if (headGap > 0.0) {
        float ts = tripStartTime(c, pp);
        if (willCollide(c - 1.0, pp, ts) || willCollide(c + 1.0, pp, ts)) {
            fragColor = vec4(0.0);
            return;
        }
    }
    float len = pp.y;
    float dim = pp.z;
    float t = columnTime(c, pp);
    float head = mod(t, pp.w) - len;
    float d = head - r;   // 这一格到亮点的距离,0 = 正被点亮

    // CRT 余晖:点亮是**硬边**,亮点前方不发光 —— 磷光体是被电子束扫到才亮的。
    // 渐变只在后面:亮点过去之后按幂次衰减,这才是余晖。
    //
    // 顺带记一个当时量出来的结论,以后要做逐格的时间过渡会再撞上:过渡区间**必须跨过
    // 一格以上**才看得见。相邻格子的 d 正好差 1,区间窄于一格时同一时刻永远只有一格
    // 处在过渡中间,空间上就是硬切;时间上也只持续(区间宽/速度)秒,等于没有。
    float rise  = step(0.0, d);
    float decay = pow(clamp(1.0 - d / len, 0.0, 1.0), 1.5);
    // 头部不能跟着 dim 一起暗下去 —— 亮头是这个效果的辨识点,每条流都该有一个。
    float headGlow = smoothstep(1.5, 0.0, abs(d));
    float bright = rise * decay * mix(dim, min(1.0, dim + 0.4), headGlow);

    // 字形:以**一趟雨**为周期,整趟里固定。
    // 不能按固定频率闪 —— 那样亮着的字符也会中途变掉。字符只该在格子看不见的时候换,
    // 而一格在一趟里唯一可见的窗口就是亮点扫过的那段,换趟时它早就归零了。
    float trip = floor(t / pp.w);
    float gi = floor(hash21(cell + vec2(trip * 31.7, trip * 17.3)) * glyphCount);

    float a = sampleGlyph(gi, inCell);
    // 二值化。点阵要的是硬边,而字形烤进图集时带了抗锯齿灰边,放大后就是一圈毛边。
    if (sharpen > 0.0) a = step(sharpen, a);

    // CRT 荧光:磷光体被打亮时会往四周洇出去一圈。在格子内朝 8 个方向偏移采样取平均,
    // 得到一层比字形本身大一圈的柔光,叠在硬边核心外面 —— 核心保持锐利,光晕负责氛围。
    float halo = 0.0;
    if (glow > 0.0) {
        float rr = glowRadius;
        float dd = rr * 0.7;
        halo = sampleGlyph(gi, inCell + vec2( rr, 0.0)) + sampleGlyph(gi, inCell + vec2(-rr, 0.0))
             + sampleGlyph(gi, inCell + vec2(0.0,  rr)) + sampleGlyph(gi, inCell + vec2(0.0, -rr))
             + sampleGlyph(gi, inCell + vec2( dd,  dd)) + sampleGlyph(gi, inCell + vec2(-dd,  dd))
             + sampleGlyph(gi, inCell + vec2( dd, -dd)) + sampleGlyph(gi, inCell + vec2(-dd, -dd));
        halo *= 0.125;
    }

    // 头部那一两格用近白色,是这个效果的辨识点
    float headMix = smoothstep(1.6, 0.0, abs(d));
    vec3 rgb = mix(baseColor.rgb, headColor.rgb, headMix);

    float b = clamp(bright, 0.0, 1.0);
    float alpha = clamp(a * b + halo * b * glow, 0.0, 1.0);

    // 扫描线:格子内按行明暗交替,不需要额外传屏幕分辨率
    if (scanline > 0.0) {
        alpha *= 1.0 - scanline * (0.5 + 0.5 * cos(inCell.y * 6.2831853 * 3.0));
    }

    // Qt 要的是 premultiplied alpha
    fragColor = vec4(rgb * alpha, alpha) * qt_Opacity;
}
