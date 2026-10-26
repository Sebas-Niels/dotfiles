pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "themes.js" as Themes

ShellRoot {
    id: root

    readonly property string themeScript: "@themeScript@"
    readonly property string fontFamily: "JetBrainsMono Nerd Font"
    readonly property var themes: Themes.list

    property bool open: false
    property string current: ""
    property bool ready: false
    property bool showPending: false
    property int selected: 0
    property string pending: ""
    property string mode: "dark"

    property real progress: open ? 1 : 0
    Behavior on progress {
        NumberAnimation {
            duration: root.open ? 460 : 280
            easing.type: root.open ? Easing.OutQuint : Easing.InOutCubic
        }
    }

    readonly property var preview: pick(themes[selected] ?? themes[0], mode)

    function pick(theme: var, variant: string): var {
        const v = theme.variants[variant] ?? theme.variants[theme.primary];
        return {
            name: theme.name,
            wallpaper: theme.wallpaper,
            thumbnail: theme.thumbnail,
            id: v.id,
            variant: v.variant,
            colors: v.colors
        };
    }

    function indexOf(id: string): int {
        for (let i = 0; i < themes.length; i++)
            for (const variant in themes[i].variants)
                if (themes[i].variants[variant].id === id)
                    return i;
        return 0;
    }

    function show() {
        if (!ready) {
            showPending = true;
            return;
        }
        selected = indexOf(current);
        const theme = themes[selected];
        mode = theme.primary;
        for (const variant in theme.variants)
            if (theme.variants[variant].id === current)
                mode = variant;
        strip.reveal(selected, true, true);
        open = true;
    }

    function hide() {
        showPending = false;
        open = false;
    }

    readonly property bool idle: !open && !showPending && progress === 0 && !applyProc.running && pending === ""
    Timer {
        running: root.idle
        interval: 1000
        onTriggered: Qt.quit()
    }

    function select(i: int, center: bool) {
        selected = Math.max(0, Math.min(themes.length - 1, i));
        strip.reveal(selected, center, false);
    }

    property real wheelDelta: 0
    function wheel(event: var) {
        const d = event.angleDelta;
        wheelDelta += Math.abs(d.y) >= Math.abs(d.x) ? -d.y : d.x;
        while (Math.abs(wheelDelta) >= 120) {
            const dir = Math.sign(wheelDelta);
            select(selected + dir, true);
            wheelDelta -= dir * 120;
        }
    }

    function apply(i: int) {
        selected = i;
        current = pick(themes[i], mode).id;
        pending = current;
        flush();
        hide();
    }

    function flush() {
        if (applyProc.running || pending === "")
            return;
        applyProc.command = [themeScript, "set", pending];
        pending = "";
        applyProc.running = true;
    }

    IpcHandler {
        target: "themes"

        function toggle(): void {
            if (root.open)
                root.hide();
            else
                root.show();
        }
        function open(): void {
            root.show();
        }
        function close(): void {
            root.hide();
        }
    }

    Process {
        running: true
        command: [root.themeScript, "current"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.current = this.text.trim();
                root.ready = true;
                if (root.showPending) {
                    root.showPending = false;
                    root.show();
                }
            }
        }
    }

    Process {
        id: applyProc
        onExited: root.flush()
    }

    PanelWindow {
        id: win

        visible: root.open || root.progress > 0.001
        color: "transparent"
        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "aperture-theme-menu"
        WlrLayershell.keyboardFocus: root.open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

        onVisibleChanged: if (visible)
            Qt.callLater(() => {
                keys.forceActiveFocus();
                strip.reveal(root.selected, true, true);
            })

        readonly property real stripHeight: Math.round(Math.max(220, Math.min(560, height * 0.42)))

        Item {
            id: ui
            visible: false

            property color bg: root.preview.colors.bg
            property color text: root.preview.colors.text
            property color subtext: root.preview.colors.subtext
            property color surface: root.preview.colors.surface
            property color overlay: root.preview.colors.overlay
            property color accent: root.preview.colors.accent

            Behavior on bg { ColorAnimation { duration: 360; easing.type: Easing.OutCubic } }
            Behavior on text { ColorAnimation { duration: 360; easing.type: Easing.OutCubic } }
            Behavior on subtext { ColorAnimation { duration: 360; easing.type: Easing.OutCubic } }
            Behavior on surface { ColorAnimation { duration: 360; easing.type: Easing.OutCubic } }
            Behavior on overlay { ColorAnimation { duration: 360; easing.type: Easing.OutCubic } }
            Behavior on accent { ColorAnimation { duration: 360; easing.type: Easing.OutCubic } }
        }

        Item {
            id: keys
            anchors.fill: parent
            focus: true

            Keys.onPressed: event => {
                const s = root.selected;
                switch (event.key) {
                case Qt.Key_Escape:
                    root.hide();
                    break;
                case Qt.Key_Left:
                case Qt.Key_H:
                case Qt.Key_Backtab:
                    root.select(s - 1, true);
                    break;
                case Qt.Key_Right:
                case Qt.Key_L:
                case Qt.Key_Tab:
                    root.select(s + 1, true);
                    break;
                case Qt.Key_Up:
                case Qt.Key_K:
                    root.mode = "light";
                    break;
                case Qt.Key_Down:
                case Qt.Key_J:
                    root.mode = "dark";
                    break;
                case Qt.Key_Home:
                    root.select(0, true);
                    break;
                case Qt.Key_End:
                    root.select(root.themes.length - 1, true);
                    break;
                case Qt.Key_Return:
                case Qt.Key_Enter:
                case Qt.Key_Space:
                    root.apply(s);
                    break;
                default:
                    return;
                }
                event.accepted = true;
            }
        }

        Item {
            id: backdrop

            property int front: 0

            anchors.fill: parent
            opacity: root.progress

            function load(source: string) {
                const old = layers.itemAt(front);
                if (!old || old.source.toString() === source)
                    return;
                front = 1 - front;
                const next = layers.itemAt(front);
                next.z = 1;
                old.z = 0;
                next.opacity = 0;
                next.source = source;
                next.reveal();
            }

            Connections {
                target: root
                function onPreviewChanged() {
                    backdrop.load(root.preview.wallpaper);
                }
            }

            Repeater {
                id: layers
                model: 2

                Image {
                    required property int index

                    function reveal() {
                        if (status === Image.Ready && index === backdrop.front)
                            opacity = 1;
                    }

                    anchors.fill: parent
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    sourceSize: Qt.size(win.width, win.height)
                    Component.onCompleted: if (index === 0)
                        source = root.preview.wallpaper
                    opacity: 0
                    onStatusChanged: reveal()

                    Behavior on opacity {
                        NumberAnimation { duration: 420; easing.type: Easing.OutCubic }
                    }
                }
            }

            Rectangle {
                z: 2
                anchors.fill: parent
                gradient: Gradient {
                    GradientStop { position: 0; color: Qt.alpha(ui.bg, 0.2) }
                    GradientStop { position: 0.55; color: Qt.alpha(ui.bg, 0.45) }
                    GradientStop { position: 1; color: Qt.alpha(ui.bg, 0.88) }
                }
            }

            MouseArea {
                z: 3
                anchors.fill: parent
                onClicked: root.hide()
            }

            WheelHandler {
                onWheel: event => root.wheel(event)
            }
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: strip.top
            anchors.bottomMargin: Math.round(win.stripHeight * 0.1)
            text: "THEMES"
            color: ui.text
            opacity: 0.75 * root.progress
            font.family: root.fontFamily
            font.pixelSize: Math.round(win.stripHeight * 0.034) + 6
            font.letterSpacing: 8
            font.weight: Font.DemiBold
        }

        Flickable {
            id: strip

            readonly property real slant: Math.round(win.stripHeight * 0.22)
            readonly property real collapsedWidth: Math.round(win.stripHeight * 0.24)
            readonly property real expandedWidth: Math.round(win.stripHeight * 1.08)
            readonly property real gap: Math.max(6, Math.round(win.stripHeight * 0.025))
            readonly property real step: collapsedWidth + gap
            readonly property real pad: Math.round(win.stripHeight * 0.12)
            readonly property real fullWidth: (root.themes.length - 1) * step + expandedWidth + slant

            property point lastPointer: Qt.point(-1, -1)

            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter
            anchors.verticalCenterOffset: -Math.round(win.stripHeight * 0.1)
            width: Math.min(fullWidth + 2 * pad, win.width)
            height: win.stripHeight
            leftMargin: pad
            rightMargin: pad
            contentWidth: row.width
            contentHeight: height
            flickableDirection: Flickable.HorizontalFlick
            boundsBehavior: Flickable.StopAtBounds

            function reveal(i: int, center: bool, instant: bool) {
                const x = i * step;
                const w = expandedWidth + slant;
                const min = -leftMargin;
                const max = Math.max(min, fullWidth + rightMargin - width);
                let to = contentX;
                if (center)
                    to = x + w / 2 - width / 2;
                else if (x - pad < contentX)
                    to = x - pad;
                else if (x + w + pad > contentX + width)
                    to = x + w + pad - width;
                to = Math.max(min, Math.min(max, to));
                if (instant || !root.open) {
                    scroll.stop();
                    contentX = to;
                } else if (to !== contentX) {
                    scroll.to = to;
                    scroll.restart();
                }
            }

            function shardAt(scene: point): int {
                for (let i = 0; i < shards.count; i++) {
                    const s = shards.itemAt(i);
                    if (s && s.hits(s.mapFromItem(null, scene.x, scene.y)))
                        return i;
                }
                return -1;
            }

            onWidthChanged: reveal(root.selected, true, true)

            WheelHandler {
                onWheel: event => root.wheel(event)
            }

            NumberAnimation {
                id: scroll
                target: strip
                property: "contentX"
                duration: 420
                easing.type: Easing.OutQuint
            }

            Row {
                id: row

                height: strip.height
                spacing: strip.gap - strip.slant

                Repeater {
                    id: shards
                    model: root.themes

                    ThemeShard {
                        height: row.height
                        slant: strip.slant
                        collapsedWidth: strip.collapsedWidth
                        expandedWidth: strip.expandedWidth
                        selected: index === root.selected
                        active: root.indexOf(root.current) === index
                        c: root.pick(modelData, root.mode).colors
                        reveal: Math.max(0, Math.min(1, root.progress * 1.7 - Math.abs(index - root.selected) * 0.07))
                    }
                }
            }

            MouseArea {
                anchors.fill: row
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor

                onPositionChanged: mouse => {
                    const scene = mapToItem(null, mouse.x, mouse.y);
                    if (pressed || (scene.x === strip.lastPointer.x && scene.y === strip.lastPointer.y))
                        return;
                    strip.lastPointer = scene;
                    const i = strip.shardAt(scene);
                    if (i >= 0 && i !== root.selected)
                        root.select(i, false);
                }

                onClicked: mouse => {
                    const i = strip.shardAt(mapToItem(null, mouse.x, mouse.y));
                    if (i < 0)
                        root.hide();
                    else if (i === root.selected)
                        root.apply(i);
                    else
                        root.select(i, false);
                }
            }
        }

        Column {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: strip.bottom
            anchors.topMargin: Math.round(win.stripHeight * 0.09)
            spacing: Math.round(win.stripHeight * 0.03)
            opacity: root.progress
            transform: Translate {
                y: 24 * (1 - root.progress)
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: root.preview.name
                color: ui.text
                font.family: root.fontFamily
                font.pixelSize: Math.round(win.stripHeight * 0.075)
                font.weight: Font.Bold
            }

            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 14

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.preview.variant + (root.preview.id === root.current ? "  ·  applied" : "")
                    color: ui.subtext
                    font.family: root.fontFamily
                    font.pixelSize: Math.round(win.stripHeight * 0.03) + 4
                }

                Row {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 6

                    Repeater {
                        model: ["accent", "accent2", "red", "yellow", "green"]

                        Rectangle {
                            required property string modelData
                            width: 14
                            height: 14
                            radius: 7
                            color: root.preview.colors[modelData]
                            border.width: 1
                            border.color: Qt.alpha(ui.text, 0.25)

                            Behavior on color {
                                ColorAnimation { duration: 360; easing.type: Easing.OutCubic }
                            }
                        }
                    }
                }
            }
        }

        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: Math.round(win.stripHeight * 0.1)
            spacing: 22
            opacity: 0.85 * root.progress

            Repeater {
                model: [["← →", "browse"], ["↑ ↓", "light / dark"], ["enter", "apply"], ["esc", "close"]]

                Row {
                    id: hint
                    required property var modelData
                    spacing: 8

                    Rectangle {
                        width: keyLabel.implicitWidth + 16
                        height: 26
                        radius: 7
                        color: Qt.alpha(ui.surface, 0.8)
                        border.width: 1
                        border.color: ui.overlay

                        Text {
                            id: keyLabel
                            anchors.centerIn: parent
                            text: hint.modelData[0]
                            color: ui.text
                            font.family: root.fontFamily
                            font.pixelSize: 13
                        }
                    }
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: hint.modelData[1]
                        color: ui.subtext
                        font.family: root.fontFamily
                        font.pixelSize: 14
                    }
                }
            }
        }
    }
}
