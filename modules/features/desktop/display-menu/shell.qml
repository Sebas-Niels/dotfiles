pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

ShellRoot {
    id: root

    readonly property string displayScript: "@displayScript@"
    readonly property string displayDaemon: "@displayDaemon@"
    readonly property string fontFamily: "JetBrainsMono Nerd Font"

    readonly property int warmest: 1500
    readonly property int coolest: 6000
    function kelvin(strength: real): int {
        return Math.round((coolest - (coolest - warmest) * strength / 100) / 50) * 50;
    }
    function strength(kelvin: int): real {
        return Math.round((coolest - kelvin) / (coolest - warmest) * 100);
    }

    property bool open: false
    property var targetScreen: null
    property real anchorX: -1

    property int brightness: 30
    property bool night: false
    property real warmth: 55

    property bool brightnessSchedule: false
    property bool nightSchedule: false
    property int nightOn: 21 * 60 + 30
    property int nightOff: 7 * 60
    property string activePoint: ""
    property bool loadPoints: true

    ListModel {
        id: points
    }

    property int pendingBrightness: -1
    property var pending: ({})

    property real progress: open ? 1 : 0
    Behavior on progress {
        NumberAnimation {
            duration: root.open ? 320 : 180
            easing.type: root.open ? Easing.OutQuint : Easing.InOutCubic
        }
    }

    function show() {
        loadPoints = true;
        status.running = true;
        cursor.running = true;
    }

    function hide() {
        open = false;
    }

    readonly property bool idle: !open && progress === 0 && !cursor.running && !status.running
        && !brightnessProc.running && pendingBrightness < 0 && !commandProc.running && Object.keys(pending).length === 0
    Timer {
        running: root.idle
        interval: 1000
        onTriggered: Qt.quit()
    }

    function setBrightness(v: int) {
        brightness = v;
        brightnessSchedule = false;
        pendingBrightness = v;
        flushBrightness();
    }

    function setNight(on: bool) {
        night = on;
        nightSchedule = false;
        queue("night", [displayScript, "night", on ? "on" : "off"]);
    }

    function setWarmth(w: real) {
        warmth = w;
        queue("warmth", [displayScript, "warmth", String(kelvin(w))]);
    }

    function flushBrightness() {
        if (brightnessProc.running || pendingBrightness < 0)
            return;
        brightnessProc.command = [displayScript, "brightness", String(pendingBrightness)];
        pendingBrightness = -1;
        brightnessProc.running = true;
    }

    function hhmm(minutes: int): string {
        const pad = n => n < 10 ? `0${n}` : `${n}`;
        return `${pad(Math.floor(minutes / 60))}:${pad(minutes % 60)}`;
    }

    function setBrightnessSchedule(on: bool) {
        brightnessSchedule = on;
        queue("brightness-schedule", [displayScript, "schedule", "brightness", on ? "on" : "off"]);
    }

    function setNightSchedule(on: bool) {
        nightSchedule = on;
        queue("night-schedule", [displayScript, "schedule", "night", on ? "on" : "off"]);
    }

    function setNightWindow(on: int, off: int) {
        nightOn = on;
        nightOff = off;
        queue("window", [displayScript, "schedule", "night", "window", hhmm(on), hhmm(off)]);
    }

    function sendPoints() {
        const args = [];
        for (let i = 0; i < points.count; i++)
            args.push(`${hhmm(points.get(i).time)}=${points.get(i).level}`);
        queue("points", [displayScript, "schedule", "brightness", "points"].concat(args));
    }

    function setPoint(i: int, time: int, level: int) {
        points.set(i, { time: time, level: level });
        sendPoints();
    }

    function addPoint() {
        const last = points.count > 0 ? points.get(points.count - 1) : { time: 20 * 60, level: brightness + 5 };
        points.append({ time: (last.time + 60) % 1440, level: Math.max(0, last.level - 5) });
        sendPoints();
    }

    function removePoint(i: int) {
        points.remove(i);
        sendPoints();
    }

    function queue(key: string, command: var) {
        const next = Object.assign({}, pending);
        next[key] = command;
        pending = next;
        flush();
    }

    function flush() {
        if (commandProc.running)
            return;
        const keys = Object.keys(pending);
        if (keys.length === 0) {
            status.running = true;
            return;
        }
        const next = Object.assign({}, pending);
        commandProc.command = next[keys[0]];
        delete next[keys[0]];
        pending = next;
        commandProc.running = true;
    }

    IpcHandler {
        target: "display"

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
        function reload(): void {
            themeFile.reload();
        }
    }

    Process {
        id: status
        running: true
        command: [root.displayScript, "status"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const s = JSON.parse(this.text);
                    if (root.pendingBrightness < 0 && !brightnessProc.running)
                        root.brightness = s.brightness;
                    if (Object.keys(root.pending).length === 0 && !commandProc.running) {
                        const minutes = t => parseInt(t.slice(0, 2)) * 60 + parseInt(t.slice(3, 5));
                        root.night = s.night;
                        root.warmth = root.strength(s.warmth);
                        root.brightnessSchedule = s.brightnessSchedule;
                        root.nightSchedule = s.nightSchedule;
                        root.nightOn = minutes(s.nightOn);
                        root.nightOff = minutes(s.nightOff);
                        if (root.loadPoints) {
                            points.clear();
                            for (const p of s.points)
                                points.append({ time: minutes(p.time), level: p.brightness });
                            root.loadPoints = false;
                        }
                    }
                    root.activePoint = s.activePoint;
                    if (s.relay === false)
                        Quickshell.execDetached([root.displayDaemon]);
                } catch (e) {}
            }
        }
    }

    Process {
        id: cursor
        command: ["mmsg", "get", "cursorpos"]
        stdout: StdioCollector {
            onStreamFinished: {
                let pos = null;
                try {
                    pos = JSON.parse(this.text);
                } catch (e) {}
                const screens = Quickshell.screens;
                let target = screens.length > 0 ? screens[0] : null;
                for (let i = 0; i < screens.length; i++)
                    if (pos && screens[i].name === pos.monitor)
                        target = screens[i];
                root.targetScreen = target;
                root.anchorX = pos && target ? pos.x - target.x : -1;
                root.open = true;
            }
        }
    }

    Process {
        id: brightnessProc
        onExited: root.flushBrightness()
    }

    Process {
        id: commandProc
        onExited: root.flush()
    }

    FileView {
        id: themeFile
        path: Quickshell.env("HOME") + "/.local/state/aperture-theme/current/display-menu.json"
        printErrors: false

        JsonAdapter {
            id: theme
            property string bg: "#212337"
            property string mantle: "#1b1d2c"
            property string surface: "#2f334d"
            property string overlay: "#444a73"
            property string text: "#e4f3fa"
            property string subtext: "#a9b8e8"
            property string accent: "#82aaff"
            property string warm: "#ffc777"
        }
    }

    Item {
        id: ui
        visible: false

        property color bg: theme.bg
        property color mantle: theme.mantle
        property color surface: theme.surface
        property color overlay: theme.overlay
        property color text: theme.text
        property color subtext: theme.subtext
        property color accent: theme.accent
        property color warm: theme.warm

        Behavior on bg { ColorAnimation { duration: 500; easing.type: Easing.OutCubic } }
        Behavior on mantle { ColorAnimation { duration: 500; easing.type: Easing.OutCubic } }
        Behavior on surface { ColorAnimation { duration: 500; easing.type: Easing.OutCubic } }
        Behavior on overlay { ColorAnimation { duration: 500; easing.type: Easing.OutCubic } }
        Behavior on text { ColorAnimation { duration: 500; easing.type: Easing.OutCubic } }
        Behavior on subtext { ColorAnimation { duration: 500; easing.type: Easing.OutCubic } }
        Behavior on accent { ColorAnimation { duration: 500; easing.type: Easing.OutCubic } }
        Behavior on warm { ColorAnimation { duration: 500; easing.type: Easing.OutCubic } }
    }

    PanelWindow {
        id: win

        readonly property int gap: 5

        screen: root.targetScreen
        visible: root.open || root.progress > 0.001
        color: "transparent"
        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }
        exclusionMode: ExclusionMode.Normal
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "aperture-display-menu"
        WlrLayershell.keyboardFocus: root.open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

        onVisibleChanged: if (visible)
            Qt.callLater(() => keys.forceActiveFocus())

        MouseArea {
            anchors.fill: parent
            enabled: root.open
            onClicked: root.hide()
        }

        Item {
            id: keys
            anchors.fill: parent
            focus: true

            Keys.onPressed: event => {
                const step = event.modifiers & Qt.ShiftModifier ? 1 : 5;
                switch (event.key) {
                case Qt.Key_Escape:
                case Qt.Key_Q:
                    root.hide();
                    break;
                case Qt.Key_Left:
                case Qt.Key_H:
                    if (!root.brightnessSchedule)
                        root.setBrightness(Math.max(0, root.brightness - step));
                    break;
                case Qt.Key_Right:
                case Qt.Key_L:
                    if (!root.brightnessSchedule)
                        root.setBrightness(Math.min(100, root.brightness + step));
                    break;
                case Qt.Key_Down:
                case Qt.Key_J:
                    root.setWarmth(Math.max(0, root.warmth - step));
                    break;
                case Qt.Key_Up:
                case Qt.Key_K:
                    root.setWarmth(Math.min(100, root.warmth + step));
                    break;
                case Qt.Key_N:
                case Qt.Key_Space:
                    if (!root.nightSchedule)
                        root.setNight(!root.night);
                    break;
                default:
                    return;
                }
                event.accepted = true;
            }
        }

        Rectangle {
            id: card

            width: 380
            height: content.implicitHeight + 48
            x: root.anchorX < 0
                ? parent.width - width - win.gap
                : Math.max(win.gap, Math.min(parent.width - width - win.gap, root.anchorX - width / 2))
            y: win.gap - 10 * (1 - root.progress)
            opacity: root.progress
            radius: 0
            color: Qt.alpha(ui.mantle, 0.94)
            border.width: 1
            border.color: Qt.alpha(ui.overlay, 0.8)

            MouseArea {
                anchors.fill: parent
            }

            Column {
                id: content
                anchors.fill: parent
                anchors.margins: 24
                spacing: 14

                Text {
                    text: "DISPLAY"
                    color: ui.subtext
                    opacity: 0.8
                    font.family: root.fontFamily
                    font.pixelSize: 13
                    font.letterSpacing: 6
                    font.weight: Font.DemiBold
                }

                Item {
                    width: parent.width
                    height: brightnessLabel.height

                    Text {
                        id: brightnessLabel
                        text: "󰃠  Brightness"
                        color: ui.text
                        font.family: root.fontFamily
                        font.pixelSize: 15
                    }
                    Text {
                        anchors.right: parent.right
                        text: `${brightnessSlider.shown}%`
                        color: ui.subtext
                        font.family: root.fontFamily
                        font.pixelSize: 15
                    }
                }

                Slider {
                    id: brightnessSlider
                    width: parent.width
                    from: 0
                    to: 100
                    value: root.brightness
                    live: false
                    enabled: !root.brightnessSchedule
                    fill: ui.accent
                    track: ui.surface
                    knob: ui.text
                    onMoved: v => root.setBrightness(v)
                }

                Item {
                    width: parent.width
                    height: brightnessScheduleToggle.height

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "󰅐  Schedule"
                        color: ui.subtext
                        font.family: root.fontFamily
                        font.pixelSize: 13
                    }
                    Toggle {
                        id: brightnessScheduleToggle
                        anchors.right: parent.right
                        implicitWidth: 38
                        implicitHeight: 22
                        checked: root.brightnessSchedule
                        on: ui.accent
                        off: ui.surface
                        knob: ui.text
                        onToggled: root.setBrightnessSchedule(!root.brightnessSchedule)
                    }
                }

                Item {
                    width: parent.width
                    height: root.brightnessSchedule ? plan.implicitHeight : 0
                    opacity: root.brightnessSchedule ? 1 : 0
                    clip: true

                    Behavior on height { NumberAnimation { duration: 240; easing.type: Easing.OutCubic } }
                    Behavior on opacity { NumberAnimation { duration: 200 } }

                    Column {
                        id: plan
                        width: parent.width
                        spacing: 12

                        Repeater {
                            model: points

                            Item {
                                id: point
                                required property int index
                                required property int time
                                required property int level

                                readonly property bool active: root.hhmm(time) === root.activePoint

                                width: plan.width
                                height: pointTime.height

                                Rectangle {
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: 6
                                    height: 6
                                    radius: 3
                                    color: ui.accent
                                    opacity: point.active ? 1 : 0

                                    Behavior on opacity { NumberAnimation { duration: 200 } }
                                }
                                TimeField {
                                    id: pointTime
                                    x: 14
                                    minutes: point.time
                                    fontFamily: root.fontFamily
                                    text: ui.text
                                    hover: ui.overlay
                                    onEdited: m => root.setPoint(point.index, m, point.level)
                                }
                                Slider {
                                    id: pointLevel
                                    anchors.verticalCenter: parent.verticalCenter
                                    x: pointTime.x + pointTime.width + 14
                                    width: parent.width - x - 72
                                    from: 0
                                    to: 100
                                    value: point.level
                                    live: false
                                    fill: ui.accent
                                    track: ui.surface
                                    knob: ui.text
                                    onMoved: v => root.setPoint(point.index, point.time, v)
                                }
                                Text {
                                    anchors.right: remove.left
                                    anchors.rightMargin: 8
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: `${pointLevel.shown}%`
                                    color: ui.subtext
                                    font.family: root.fontFamily
                                    font.pixelSize: 13
                                }
                                Text {
                                    id: remove
                                    anchors.right: parent.right
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: "󰅖"
                                    color: removeArea.containsMouse ? ui.text : ui.subtext
                                    opacity: removeArea.containsMouse ? 1 : 0.6
                                    font.family: root.fontFamily
                                    font.pixelSize: 15

                                    MouseArea {
                                        id: removeArea
                                        anchors.fill: parent
                                        anchors.margins: -4
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: root.removePoint(point.index)
                                    }
                                }
                            }
                        }

                        Rectangle {
                            width: parent.width
                            height: 30
                            radius: 0
                            color: addArea.containsMouse ? ui.surface : "transparent"
                            border.width: 1
                            border.color: Qt.alpha(ui.overlay, 0.8)

                            Behavior on color { ColorAnimation { duration: 120 } }

                            Text {
                                anchors.centerIn: parent
                                text: "󰐕  Add point"
                                color: ui.subtext
                                font.family: root.fontFamily
                                font.pixelSize: 13
                            }
                            MouseArea {
                                id: addArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.addPoint()
                            }
                        }

                        Text {
                            width: parent.width
                            wrapMode: Text.WordWrap
                            text: "Each point sets the brightness from its time onwards. Turn the schedule off to adjust brightness by hand."
                            color: ui.subtext
                            opacity: 0.7
                            font.family: root.fontFamily
                            font.pixelSize: 12
                        }
                    }
                }

                Rectangle {
                    width: parent.width
                    height: 1
                    color: Qt.alpha(ui.overlay, 0.6)
                }

                Item {
                    width: parent.width
                    height: nightToggle.height

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "󰖔  Night light"
                        color: ui.text
                        font.family: root.fontFamily
                        font.pixelSize: 15
                    }
                    Toggle {
                        id: nightToggle
                        anchors.right: parent.right
                        checked: root.night
                        on: ui.warm
                        off: ui.surface
                        knob: ui.text
                        enabled: !root.nightSchedule
                        onToggled: root.setNight(!root.night)
                    }
                }

                Item {
                    width: parent.width
                    height: warmthLabel.height
                    opacity: root.night || root.nightSchedule ? 1 : 0.4

                    Behavior on opacity { NumberAnimation { duration: 200 } }

                    Text {
                        id: warmthLabel
                        text: "Warmth"
                        color: ui.subtext
                        font.family: root.fontFamily
                        font.pixelSize: 13
                    }
                    Text {
                        anchors.right: parent.right
                        text: `${root.kelvin(root.warmth)}K`
                        color: ui.subtext
                        font.family: root.fontFamily
                        font.pixelSize: 13
                    }
                }

                Slider {
                    width: parent.width
                    from: 0
                    to: 100
                    value: root.warmth
                    enabled: root.night || root.nightSchedule
                    gradient: true
                    fill: ui.warm
                    track: ui.surface
                    knob: ui.text
                    onMoved: v => root.setWarmth(v)
                }

                Item {
                    width: parent.width
                    height: nightScheduleToggle.height

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "󰅐  Schedule"
                        color: ui.subtext
                        font.family: root.fontFamily
                        font.pixelSize: 13
                    }
                    Toggle {
                        id: nightScheduleToggle
                        anchors.right: parent.right
                        implicitWidth: 38
                        implicitHeight: 22
                        checked: root.nightSchedule
                        on: ui.warm
                        off: ui.surface
                        knob: ui.text
                        onToggled: root.setNightSchedule(!root.nightSchedule)
                    }
                }

                Item {
                    width: parent.width
                    height: root.nightSchedule ? nightPlan.implicitHeight : 0
                    opacity: root.nightSchedule ? 1 : 0
                    clip: true

                    Behavior on height { NumberAnimation { duration: 240; easing.type: Easing.OutCubic } }
                    Behavior on opacity { NumberAnimation { duration: 200 } }

                    Column {
                        id: nightPlan
                        width: parent.width
                        spacing: 12

                        Item {
                            width: parent.width
                            height: nightOnField.height

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                x: 14
                                text: "On from"
                                color: ui.subtext
                                font.family: root.fontFamily
                                font.pixelSize: 13
                            }
                            Row {
                                anchors.right: parent.right
                                spacing: 8

                                TimeField {
                                    id: nightOnField
                                    minutes: root.nightOn
                                    fontFamily: root.fontFamily
                                    text: ui.text
                                    hover: ui.overlay
                                    onEdited: m => root.setNightWindow(m, root.nightOff)
                                }
                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: "to"
                                    color: ui.subtext
                                    font.family: root.fontFamily
                                    font.pixelSize: 13
                                }
                                TimeField {
                                    minutes: root.nightOff
                                    fontFamily: root.fontFamily
                                    text: ui.text
                                    hover: ui.overlay
                                    onEdited: m => root.setNightWindow(root.nightOn, m)
                                }
                            }
                        }

                        Text {
                            width: parent.width
                            wrapMode: Text.WordWrap
                            text: "The schedule switches the night light; turn it off to switch by hand. Warmth stays adjustable."
                            color: ui.subtext
                            opacity: 0.7
                            font.family: root.fontFamily
                            font.pixelSize: 12
                        }
                    }
                }
            }
        }
    }
}
