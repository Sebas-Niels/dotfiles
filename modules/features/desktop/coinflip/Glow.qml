import QtQuick
import QtQuick.Shapes

// A soft round spot of colour that fades out towards the edge of the item, squashed to an
// ellipse by `squash`
Shape {
    id: glow

    property color color
    property real squash: 1

    preferredRendererType: Shape.CurveRenderer
    transform: Scale {
        origin.y: glow.height / 2
        yScale: glow.squash
    }

    ShapePath {
        strokeWidth: -1
        fillGradient: RadialGradient {
            centerX: glow.width / 2
            centerY: glow.height / 2
            centerRadius: glow.width / 2
            focalX: glow.width / 2
            focalY: glow.height / 2
            GradientStop { position: 0; color: glow.color }
            GradientStop { position: 0.4; color: Qt.alpha(glow.color, glow.color.a * 0.6) }
            GradientStop { position: 1; color: Qt.alpha(glow.color, 0) }
        }
        PathRectangle {
            width: glow.width
            height: glow.height
        }
    }
}
