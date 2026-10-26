import QtQuick

Item {
    id: slider

    property real from: 0
    property real to: 100
    property real step: 1
    property real value: 0
    property color fill: "#82aaff"
    property color track: "#2f334d"
    property color knob: "#e4f3fa"
    property bool gradient: false

    property bool live: true

    signal moved(real value)

    property real dragValue: 0
    readonly property bool dragging: drag.pressed
    readonly property real shown: dragging && !live ? dragValue : value
    readonly property real ratio: (shown - from) / (to - from)

    implicitHeight: 28
    opacity: enabled ? 1 : 0.4

    Behavior on opacity { NumberAnimation { duration: 200 } }

    function snap(v: real): real {
        return Math.round(Math.max(from, Math.min(to, v)) / step) * step;
    }

    function set(v: real) {
        const snapped = snap(v);
        if (snapped !== value)
            moved(snapped);
    }

    Rectangle {
        id: groove
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width
        height: 8
        radius: 0
        color: slider.track

        Rectangle {
            visible: !slider.gradient
            height: parent.height
            radius: parent.radius
            width: Math.max(height, parent.width * slider.ratio)
            color: slider.fill
        }

        Rectangle {
            visible: slider.gradient
            anchors.fill: parent
            radius: parent.radius
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0; color: slider.track }
                GradientStop { position: 1; color: slider.fill }
            }
        }
    }

    Rectangle {
        property real size: drag.pressed ? 22 : drag.containsMouse ? 20 : 18
        width: size
        height: size
        radius: size / 2
        x: (slider.width - 18) * slider.ratio - (size - 18) / 2
        anchors.verticalCenter: parent.verticalCenter
        color: slider.knob
        border.width: 3
        border.color: slider.fill

        Behavior on size { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
    }

    MouseArea {
        id: drag
        anchors.fill: parent
        anchors.margins: -6
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        preventStealing: true

        function at(x: real) {
            const v = slider.from + (slider.to - slider.from) * (x - 6 - 9) / (slider.width - 18);
            if (slider.live)
                slider.set(v);
            else
                slider.dragValue = slider.snap(v);
        }

        onPressed: mouse => at(mouse.x)
        onPositionChanged: mouse => {
            if (pressed)
                at(mouse.x);
        }
        onReleased: {
            if (!slider.live)
                slider.set(slider.dragValue);
        }
        onWheel: wheel => {
            const d = Math.abs(wheel.angleDelta.y) >= Math.abs(wheel.angleDelta.x) ? wheel.angleDelta.y : -wheel.angleDelta.x;
            slider.set(slider.value + Math.sign(d) * slider.step * (wheel.modifiers & Qt.ShiftModifier ? 1 : 5));
        }
    }
}
