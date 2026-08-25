// SDDM 主题:复刻 config/hypr/hyprlock.conf 的视觉语言
//
// 排版对齐 hyprlock:时间在中心上方 420、日期上方 280、密码框居中,
// 尺寸按屏幕高度相对 1440 自适应,详见下方 s 的注释。

import QtQuick 2.15

Item {
    id: root

    // hyprlock.conf 里的尺寸是按 2560x1440 逻辑屏写的(显示器 3840x2160 @scale 1.5)。
    // SDDM 给的坐标空间不固定 —— test-mode 下是 1707x960(DPR 2.25),真实会话又是另一个值,
    // 所以不能写死倍数,得按屏幕尺寸对 1440 取比例。
    //
    // 用短边而不是 height:HDMI-A-1 是竖屏(transform=1),那边 height 变成长边,
    // 拿 height 算会把整个界面放大 1.78 倍。UI 尺寸跟短边走才与屏幕方向无关。
    property real userScale: config.scale ? parseFloat(config.scale) : 1.0
    property real s: (Math.min(width, height) / 1440) * userScale

    property color cFg:      config.colorForeground || "#f5f5f7"
    property color cMuted:   config.colorMuted      || "#98989d"
    property color cSurface: config.colorSurface    || "#1c1c1e"
    property color cOk:      config.colorSuccess    || "#34c759"
    property color cFail:    config.colorFailure    || "#ff453a"

    // 登录失败时把提示染红,成功前保持静默(与 hyprlock 的 fail_text 行为一致)
    property string notice: ""
    property bool   noticeIsError: false

    LayoutMirroring.enabled: false


    // 背景按屏幕方向选:hyprlock 给 DP-1(横) 和 HDMI-A-1(竖) 配的是两张不同的图。
    // 这里按方向而不是显示器名判断 —— 换线/改名都不受影响,也能自动适配新接的屏。
    Image {
        anchors.fill: parent
        source: (root.width < root.height)
                ? (config.backgroundPortrait || "background-portrait.png")
                : (config.background || "background.png")
        fillMode: Image.PreserveAspectCrop
        asynchronous: false
        cache: true
    }

    // 压暗一层,保证浅色壁纸下文字仍然可读
    Rectangle {
        anchors.fill: parent
        color: "#000000"
        opacity: 0.25
    }

    // ── 时间 ──────────────────────────────────────────────
    Text {
        id: clock
        anchors.horizontalCenter: parent.horizontalCenter
        y: parent.height / 2 - 420 * s - height / 2
        color: cFg
        font.family: "Noto Sans"
        font.pixelSize: 100 * s
        font.weight: Font.Light
        text: Qt.formatDateTime(new Date(), "HH:mm")

        Timer {
            interval: 1000; running: true; repeat: true
            onTriggered: clock.text = Qt.formatDateTime(new Date(), "HH:mm")
        }
    }

    // ── 日期 ──────────────────────────────────────────────
    Text {
        id: dateLabel
        anchors.horizontalCenter: parent.horizontalCenter
        y: parent.height / 2 - 280 * s - height / 2
        color: Qt.rgba(cFg.r, cFg.g, cFg.b, 0.8)   // hyprlock 里是 f5f5f7cc
        font.family: "Noto Sans"
        font.pixelSize: 45 * s
        text: Qt.formatDateTime(new Date(), "dddd, MMMM d, yyyy")

        Timer {
            interval: 60000; running: true; repeat: true
            onTriggered: dateLabel.text = Qt.formatDateTime(new Date(), "dddd, MMMM d, yyyy")
        }
    }

    // ── 用户名 ────────────────────────────────────────────
    Text {
        id: userLabel
        anchors.horizontalCenter: parent.horizontalCenter
        y: passwordBox.y - height - 18 * s
        color: Qt.rgba(cFg.r, cFg.g, cFg.b, 0.9)
        font.family: "Noto Sans"
        font.pixelSize: 20 * s
        text: userModel.count > 0
              ? (userModel.data(userModel.index(userModel.lastIndex, 0), Qt.UserRole + 2) || "")
              : ""
    }

    // ── 密码框(hyprlock: 280x44, rounding 22, 1px 描边)────
    Rectangle {
        id: passwordBox
        width: 280 * s
        height: 44 * s
        radius: 22 * s
        anchors.horizontalCenter: parent.horizontalCenter
        y: parent.height / 2 - height / 2

        color: Qt.rgba(cSurface.r, cSurface.g, cSurface.b, 0.7)   // 1c1c1eb3
        border.width: 1
        border.color: noticeIsError ? cFail : Qt.rgba(1, 1, 1, 0.1)

        Behavior on border.color { ColorAnimation { duration: 150 } }

        TextInput {
            id: passwordInput
            anchors.fill: parent
            anchors.leftMargin: 18 * s
            anchors.rightMargin: 18 * s
            verticalAlignment: TextInput.AlignVCenter
            horizontalAlignment: TextInput.AlignHCenter

            echoMode: TextInput.Password
            passwordCharacter: "●"
            passwordMaskDelay: 0
            color: cFg
            font.family: "Noto Sans"
            font.pixelSize: 16 * s
            selectByMouse: true
            focus: true
            clip: true

            onAccepted: root.doLogin()
            onTextChanged: if (root.notice !== "") { root.notice = ""; root.noticeIsError = false }

            Text {
                anchors.centerIn: parent
                visible: passwordInput.text.length === 0
                color: cMuted
                font.family: "Noto Sans"
                font.pixelSize: 16 * s
                font.italic: true
                text: "Enter Password"
            }
        }
    }

    // ── 提示 / 失败信息 ───────────────────────────────────
    Text {
        anchors.horizontalCenter: parent.horizontalCenter
        y: passwordBox.y + passwordBox.height + 16 * s
        color: noticeIsError ? cFail : cMuted
        font.family: "Noto Sans"
        font.pixelSize: 15 * s
        font.italic: true
        text: root.notice
        opacity: text === "" ? 0 : 1
        Behavior on opacity { NumberAnimation { duration: 150 } }
    }

    // ── 底部左:会话 / 键盘布局 ────────────────────────────
    Row {
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        anchors.margins: 32 * s
        spacing: 24 * s

        PillButton {
            visible: sessionModel.count > 1
            label: sessionModel.data(sessionModel.index(sessionCombo.idx, 0), Qt.UserRole + 4) || "Session"
            onClicked: sessionCombo.idx = (sessionCombo.idx + 1) % sessionModel.count
        }

        PillButton {
            visible: keyboard.layouts.length > 1
            label: keyboard.layouts[keyboard.currentLayout] ? keyboard.layouts[keyboard.currentLayout].shortName : ""
            onClicked: keyboard.currentLayout = (keyboard.currentLayout + 1) % keyboard.layouts.length
        }
    }

    QtObject {
        id: sessionCombo
        property int idx: sessionModel.lastIndex
    }

    // ── 底部右:电源 ───────────────────────────────────────
    Row {
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: 32 * s
        spacing: 12 * s

        // 不按 sddm.canX 过滤:test-mode 下这些属性为 false,而真实会话里权限由 SDDM 自己把关
        PillButton { label: "Suspend";  onClicked: sddm.suspend() }
        PillButton { label: "Reboot";   onClicked: sddm.reboot() }
        PillButton { label: "Shutdown"; onClicked: sddm.powerOff() }
    }

    // 复用的胶囊按钮,沿用 waybar 的 hover/active 透明度(0.08 / 0.14)
    component PillButton: Rectangle {
        property string label: ""
        signal clicked()

        width: txt.implicitWidth + 28 * root.s
        height: 34 * root.s
        radius: height / 2
        color: ma.pressed  ? Qt.rgba(1, 1, 1, 0.14)
             : ma.containsMouse ? Qt.rgba(1, 1, 1, 0.08)
             : Qt.rgba(root.cSurface.r, root.cSurface.g, root.cSurface.b, 0.55)
        border.width: 1
        border.color: Qt.rgba(1, 1, 1, 0.07)

        Behavior on color { ColorAnimation { duration: 120 } }

        Text {
            id: txt
            anchors.centerIn: parent
            text: parent.label
            color: root.cFg
            font.family: "Noto Sans"
            font.pixelSize: 14 * root.s
        }

        MouseArea {
            id: ma
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: parent.clicked()
        }
    }

    function doLogin() {
        if (userModel.count === 0) return
        var user = userModel.data(userModel.index(userModel.lastIndex, 0), Qt.UserRole + 1)
        sddm.login(user, passwordInput.text, sessionCombo.idx)
    }

    Connections {
        target: sddm
        function onLoginFailed() {
            root.notice = "Authentication failed"
            root.noticeIsError = true
            passwordInput.text = ""
            passwordInput.forceActiveFocus()
        }
        function onLoginSucceeded() {
            root.notice = ""
            root.noticeIsError = false
        }
        function onInformationMessage(message) {
            root.notice = message
            root.noticeIsError = false
        }
    }

    Component.onCompleted: passwordInput.forceActiveFocus()
}
