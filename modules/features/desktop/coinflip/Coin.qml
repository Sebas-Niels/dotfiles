import QtQuick

Item {
    id: coin

    property real angle: 0
    property real size: 170
    property real thickness: 12

    property color metal
    property color metalLight
    property color metalDark
    property color rim

    readonly property real cosA: Math.cos(angle * Math.PI / 180)
    readonly property real sinA: Math.sin(angle * Math.PI / 180)
    readonly property real squash: Math.max(0.004, Math.abs(cosA))
    readonly property real tilt: cosA >= 0 ? -sinA : sinA

    width: size
    height: size

    Repeater {
        id: layers
        model: Math.max(2, Math.round(coin.thickness))

        Rectangle {
            required property int index
            readonly property real depth: 1 - index / layers.count

            width: coin.size
            height: coin.size
            radius: coin.size / 2
            y: coin.sinA * coin.thickness * depth
            color: Qt.tint(coin.rim, Qt.alpha(coin.metalDark, 0.6 * depth))
            transform: Scale {
                origin.x: coin.size / 2
                origin.y: coin.size / 2
                yScale: coin.squash
            }
        }
    }

    Face {
        size: coin.size
        heads: coin.cosA >= 0
        metal: coin.metal
        metalLight: coin.metalLight
        metalDark: coin.metalDark
        transform: Scale {
            origin.x: coin.size / 2
            origin.y: coin.size / 2
            yScale: coin.squash
        }

        Rectangle {
            anchors.fill: parent
            radius: width / 2
            color: coin.tilt > 0 ? "white" : "black"
            opacity: Math.abs(coin.tilt) * (coin.tilt > 0 ? 0.28 : 0.35)
        }
    }
}
