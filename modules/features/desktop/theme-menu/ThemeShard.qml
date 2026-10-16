import QtQuick
import QtQuick.Effects
import QtQuick.Shapes

Item {
    id: shard

    required property var modelData
    required property int index

    property bool selected: false
    property bool active: false
    property real reveal: 1

    property real collapsedWidth: 140
    property real expandedWidth: 560
    property real slant: 110

    readonly property var c: modelData.colors

    property real shardWidth: selected ? expandedWidth : collapsedWidth
    Behavior on shardWidth {
        NumberAnimation { duration: 420; easing.type: Easing.OutQuint }
    }

    width: shardWidth + slant
    opacity: reveal
    transform: Translate {
        y: 48 * (1 - shard.reveal)
    }

    function hits(p: point): bool {
        if (p.y < 0 || p.y > height)
            return false;
        const left = slant * (1 - p.y / height);
        return p.x >= left && p.x <= left + shardWidth;
    }

    Item {
        id: content

        anchors.fill: parent
        visible: false
        layer.enabled: true

        Image {
            anchors.fill: parent
            source: shard.modelData.thumbnail
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            smooth: true
            scale: shard.selected ? 1 : 1.12

            Behavior on scale {
                NumberAnimation { duration: 520; easing.type: Easing.OutQuint }
            }
        }

        Rectangle {
            anchors.fill: parent
            color: "#000000"
            opacity: shard.selected ? 0 : 0.42

            Behavior on opacity {
                NumberAnimation { duration: 300; easing.type: Easing.OutCubic }
            }
        }
    }

    Shape {
        id: mask

        anchors.fill: parent
        visible: false
        layer.enabled: true
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            strokeWidth: -1
            fillColor: "white"
            startX: shard.slant
            startY: 0
            PathLine { x: shard.width; y: 0 }
            PathLine { x: shard.shardWidth; y: shard.height }
            PathLine { x: 0; y: shard.height }
            PathLine { x: shard.slant; y: 0 }
        }
    }

    MultiEffect {
        anchors.fill: parent
        source: content
        maskEnabled: true
        maskSource: mask
        maskThresholdMin: 0.5
        maskSpreadAtMin: 1
    }

    Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer
        opacity: shard.selected ? 1 : 0

        Behavior on opacity {
            NumberAnimation { duration: 260; easing.type: Easing.OutCubic }
        }

        ShapePath {
            strokeColor: shard.c.accent
            strokeWidth: 3
            fillColor: "transparent"
            joinStyle: ShapePath.MiterJoin
            startX: shard.slant
            startY: 0
            PathLine { x: shard.width; y: 0 }
            PathLine { x: shard.shardWidth; y: shard.height }
            PathLine { x: 0; y: shard.height }
            PathLine { x: shard.slant; y: 0 }
        }
    }

    Rectangle {
        y: shard.height - height - 16
        x: shard.slant * (1 - (y + height / 2) / shard.height) + shard.shardWidth / 2 - width / 2
        width: 10
        height: 10
        radius: 5
        color: shard.c.accent
        border.width: 2
        border.color: shard.c.bg
        scale: shard.active ? 1 : 0

        Behavior on scale {
            NumberAnimation { duration: 360; easing.type: Easing.OutBack; easing.overshoot: 2.2 }
        }
    }
}
