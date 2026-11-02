// The N9 text field's shape (blanco textedit background): a squircle as tall as the field (n = 2.8, the icons' curve),
// cut in half and pulled apart, joined by straight edges. A text field's `background` (a 1 px rim, the accent when
// focused), or a button's face (set fill, and rim "transparent"). Buttons have the same ends (blanco button background).
import QtQuick

Canvas {
    property bool focused: false
    property color fill: Qt.rgba(1, 1, 1, 0.08)
    property color rim: focused ? "#2A86D8" : Qt.rgba(1, 1, 1, 0.22)
    implicitHeight: 40
    onFocusedChanged: requestPaint()
    onFillChanged: requestPaint()
    onRimChanged: requestPaint()
    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()
    onPaint: {
        const c = getContext("2d"); c.reset()
        const w = focused ? 2 : 1, s = height / 2 - w / 2, n = 2.8
        c.beginPath()
        // a quarter of the squircle at each corner, centred (cx, cy), from angle a0
        const quarter = (cx, cy, a0) => {
            for (let i = 0; i <= 24; i++) {
                const a = (a0 + i * 90 / 24) * Math.PI / 180, co = Math.cos(a), si = Math.sin(a)
                const x = cx + s * Math.sign(co) * Math.pow(Math.abs(co), 2 / n), y = cy + s * Math.sign(si) * Math.pow(Math.abs(si), 2 / n)
                if (i === 0 && a0 === 0) c.moveTo(x, y); else c.lineTo(x, y)
            }
        }
        const r = height / 2
        quarter(width - r, r, 0); quarter(r, r, 90); quarter(r, r, 180); quarter(width - r, r, 270)
        c.closePath()
        c.fillStyle = fill; c.fill()
        c.lineWidth = w; c.strokeStyle = rim; c.stroke()
    }
}
