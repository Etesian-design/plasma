// The N9 squircle (superellipse, n = 4) as a filled shape; children are centred on it.
import QtQuick
import QtQuick.Shapes

Shape {
    id: sq
    property real size: 26
    property color fill: "#3A3A3A"
    /** optional top colour: the shape is filled with a vertical gradient from it to `fill` (the lit accent squircle) */
    property color fillFrom: fill
    /** an outline, e.g. the accent ring around today (none by default) */
    property color stroke: "transparent"
    property real strokeWidth: -1
    width: size; height: size
    preferredRendererType: Shape.CurveRenderer
    ShapePath {
        strokeWidth: sq.strokeWidth
        strokeColor: sq.stroke
        fillGradient: LinearGradient {
            y1: 0; y2: sq.size
            GradientStop { position: 0; color: sq.fillFrom }
            GradientStop { position: 1; color: sq.fill }
        }
        PathPolyline {
            path: {
                const pts = [], r = sq.size / 2
                for (let i = 0; i <= 64; i++) {
                    const t = i / 64 * 2 * Math.PI, c = Math.cos(t), s = Math.sin(t)
                    pts.push(Qt.point(r + r * Math.sign(c) * Math.sqrt(Math.abs(c)), r + r * Math.sign(s) * Math.sqrt(Math.abs(s))))
                }
                return pts
            }
        }
    }
}
