import QtQuick

Rectangle {
    id: toggle

    property bool checked: false
    property color on: "#82aaff"
    property color off: "#2f334d"
    property color knob: "#e4f3fa"

    signal toggled

    implicitWidth: 46
    implicitHeight: 26
    radius: height / 2
    color: checked ? on : off
    opacity: enabled ? 1 : 0.4

    Behavior on color { ColorAnimation { duration: 200 } }
    Behavior on opacity { NumberAnimation { duration: 200 } }

    Rectangle {
        width: parent.height - 8
        height: width
        radius: width / 2
        anchors.verticalCenter: parent.verticalCenter
        x: toggle.checked ? parent.width - width - 4 : 4
        color: toggle.knob

        Behavior on x { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: toggle.toggled()
    }
}
