import QtQuick

Rectangle {
    id: field

    property int minutes: 0
    property string fontFamily: "monospace"
    property color text: "#e4f3fa"
    property color hover: "#444a73"

    signal edited(int minutes)

    implicitWidth: row.implicitWidth + 16
    implicitHeight: row.implicitHeight + 8
    radius: 8
    color: "transparent"
    border.width: 1
    border.color: hover

    function pad(n: int): string {
        return n < 10 ? `0${n}` : `${n}`;
    }

    function shift(delta: int) {
        edited(((minutes + delta) % 1440 + 1440) % 1440);
    }

    Row {
        id: row
        anchors.centerIn: parent

        Repeater {
            model: [
                { step: 60, fine: 60 },
                { step: 5, fine: 1 }
            ]

            Row {
                id: part
                required property var modelData
                required property int index

                Text {
                    visible: part.index > 0
                    text: ":"
                    color: field.text
                    font.family: field.fontFamily
                    font.pixelSize: 15
                }

                Rectangle {
                    width: digits.implicitWidth + 4
                    height: digits.implicitHeight
                    radius: 4
                    color: area.containsMouse ? field.hover : "transparent"

                    Behavior on color { ColorAnimation { duration: 120 } }

                    Text {
                        id: digits
                        anchors.centerIn: parent
                        text: field.pad(part.index === 0 ? Math.floor(field.minutes / 60) : field.minutes % 60)
                        color: field.text
                        font.family: field.fontFamily
                        font.pixelSize: 15
                    }

                    MouseArea {
                        id: area
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        acceptedButtons: Qt.LeftButton | Qt.RightButton

                        function step(modifiers: int): int {
                            return modifiers & Qt.ShiftModifier ? part.modelData.fine : part.modelData.step;
                        }

                        onClicked: mouse => field.shift((mouse.button === Qt.RightButton ? -1 : 1) * step(mouse.modifiers))
                        onWheel: wheel => {
                            const d = Math.abs(wheel.angleDelta.y) >= Math.abs(wheel.angleDelta.x) ? wheel.angleDelta.y : -wheel.angleDelta.x;
                            if (d !== 0)
                                field.shift(Math.sign(d) * step(wheel.modifiers));
                        }
                    }
                }
            }
        }
    }
}
