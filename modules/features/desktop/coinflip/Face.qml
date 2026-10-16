import QtQuick
import QtQuick.Shapes

Item {
    id: face

    property real size: 170
    property bool heads: true

    property color metal
    property color metalLight
    property color metalDark

    width: size
    height: size

    function circle(cx: real, cy: real, r: real): string {
        return `M ${cx - r} ${cy} A ${r} ${r} 0 1 0 ${cx + r} ${cy} A ${r} ${r} 0 1 0 ${cx - r} ${cy} Z`;
    }

    function sun(): string {
        let p = circle(50, 50, 13);
        for (let i = 0; i < 12; i++) {
            const a = i * Math.PI / 6;
            const tip = i % 2 === 0 ? 33 : 26;
            const half = 0.13;
            const pt = (r, t) => `${50 + r * Math.cos(t)} ${50 + r * Math.sin(t)}`;
            p += ` M ${pt(17, a - half)} L ${pt(tip, a)} L ${pt(17, a + half)} Z`;
        }
        return p;
    }

    function crescent(x1: real, y1: real, r1: real, x2: real, y2: real, r2: real): string {
        const dx = x2 - x1, dy = y2 - y1;
        const d = Math.hypot(dx, dy);
        const a = (r1 * r1 - r2 * r2 + d * d) / (2 * d);
        const h = Math.sqrt(r1 * r1 - a * a);
        const ux = dx / d, uy = dy / d;
        const px = x1 + a * ux, py = y1 + a * uy;
        const p1 = [px - h * uy, py + h * ux];
        const p2 = [px + h * uy, py - h * ux];
        const sweep = (from, mid, cx, cy) => ((from[0] - cx) * (mid[1] - cy) - (from[1] - cy) * (mid[0] - cx)) > 0 ? 1 : 0;
        const m1 = [x1 - r1 * ux, y1 - r1 * uy];
        const m2 = [x2 - r2 * ux, y2 - r2 * uy];
        return `M ${p1[0]} ${p1[1]} A ${r1} ${r1} 0 ${a > 0 ? 1 : 0} ${sweep(p1, m1, x1, y1)} ${p2[0]} ${p2[1]} `
            + `A ${r2} ${r2} 0 ${a > d ? 1 : 0} ${sweep(p2, m2, x2, y2)} ${p1[0]} ${p1[1]} Z`;
    }

    function sparkle(x: real, y: real, r: real): string {
        return `M ${x} ${y - r} Q ${x} ${y} ${x + r} ${y} Q ${x} ${y} ${x} ${y + r} `
            + `Q ${x} ${y} ${x - r} ${y} Q ${x} ${y} ${x} ${y - r} Z`;
    }

    readonly property string emblem: heads ? sun()
        : crescent(46, 53, 25, 57, 44, 21) + " " + sparkle(74, 33, 6.5) + " " + sparkle(79, 52, 4)

    Item {
        width: 100
        height: 100
        scale: face.size / 100
        transformOrigin: Item.TopLeft

        Shape {
            anchors.fill: parent
            preferredRendererType: Shape.CurveRenderer

            ShapePath {
                strokeWidth: -1
                fillGradient: RadialGradient {
                    centerX: 34
                    centerY: 28
                    centerRadius: 78
                    focalX: 34
                    focalY: 28
                    GradientStop { position: 0; color: face.metalLight }
                    GradientStop { position: 0.5; color: face.metal }
                    GradientStop { position: 1; color: face.metalDark }
                }
                PathSvg { path: face.circle(50, 50, 50) }
            }

            ShapePath {
                fillColor: "transparent"
                strokeColor: Qt.alpha(face.metalDark, 0.9)
                strokeWidth: 1.2
                PathSvg { path: face.circle(50, 50, 44.5) }
            }
            ShapePath {
                fillColor: "transparent"
                strokeColor: Qt.alpha(face.metalLight, 0.7)
                strokeWidth: 0.8
                PathSvg { path: face.circle(50, 50, 45.6) }
            }

            ShapePath {
                fillColor: "transparent"
                strokeColor: Qt.alpha(face.metalDark, 0.75)
                strokeWidth: 1.6
                capStyle: ShapePath.RoundCap
                strokeStyle: ShapePath.DashLine
                dashPattern: [0.01, 2.6]
                PathAngleArc {
                    centerX: 50
                    centerY: 50
                    radiusX: 40.5
                    radiusY: 40.5
                    startAngle: 0
                    sweepAngle: 360
                }
            }
        }

        Repeater {
            model: [
                { dx: 0.9, dy: 1.1, color: Qt.alpha(face.metalDark, 0.95) },
                { dx: -0.6, dy: -0.7, color: face.metalLight },
                { dx: 0, dy: 0, color: Qt.tint(face.metal, Qt.alpha(face.metalLight, 0.25)) }
            ]

            Shape {
                required property var modelData
                x: modelData.dx
                y: modelData.dy
                width: 100
                height: 100
                preferredRendererType: Shape.CurveRenderer

                ShapePath {
                    strokeWidth: -1
                    fillColor: modelData.color
                    fillRule: ShapePath.WindingFill
                    PathSvg { path: face.emblem }
                }
            }
        }
    }
}
