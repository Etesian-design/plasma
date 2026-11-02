/*
 * Super+Z (etesian-design src/shell/desktop/XLayoutPicker.vue): the snap-layout picker for the active window, at the top
 * of its screen. 1-6 picks a layout and then a number its zone, or click a zone; Esc or a click elsewhere closes it.
 * It is an effect rather than part of the etesian-snap script because effects get the keyboard. Zones follow geometry.ts
 * zoneRects() exactly as the script does.
 */
import QtQuick
import org.kde.kwin as KWin

KWin.SceneEffect {
    id: effect

    readonly property int gap: 8
    readonly property var layouts: [
        { label: "1/2 + 1/2", zones: [[0, 0, .5, 1], [.5, 0, .5, 1]] },
        { label: "Three columns", zones: [[0, 0, 1 / 3, 1], [1 / 3, 0, 1 / 3, 1], [2 / 3, 0, 1 / 3, 1]] },
        { label: "2/3 + 1/3", zones: [[0, 0, 2 / 3, 1], [2 / 3, 0, 1 / 3, 1]] },
        { label: "Focus centre", zones: [[0, 0, .25, 1], [.25, 0, .5, 1], [.75, 0, .25, 1]] },
        { label: "Main + stack", zones: [[0, 0, .5, 1], [.5, 0, .5, .5], [.5, .5, .5, .5]] },
        { label: "Quarters", zones: [[0, 0, .5, .5], [.5, 0, .5, .5], [0, .5, .5, .5], [.5, .5, .5, .5]] },
    ]
    property var target: null

    function zone(layout, index, a) {
        const [fx, fy, fw, fh] = layouts[layout].zones[index]
        const x0 = Math.round(a.x + fx * a.width), x1 = Math.round(a.x + (fx + fw) * a.width)
        const y0 = Math.round(a.y + fy * a.height), y1 = Math.round(a.y + (fy + fh) * a.height)
        const l = x0 + (fx === 0 ? gap : gap / 2), r = x1 - (fx + fw >= 0.999 ? gap : gap / 2)
        const t = y0 + (fy === 0 ? gap : gap / 2), b = y1 - (fy + fh >= 0.999 ? gap : gap / 2)
        return Qt.rect(l, t, r - l, b - t)
    }
    function pick(layout, index) {
        const w = target
        visible = false; target = null
        if (!w) return
        w.setMaximize(false, false)
        w.frameGeometry = zone(layout, index, KWin.Workspace.clientArea(KWin.Workspace.MaximizeArea, w))
    }

    KWin.ShortcutHandler {
        name: "Etesian Snap Layouts"
        text: "Etesian: snap layouts picker"
        sequence: "Meta+Z"
        onActivated: {
            if (effect.visible) { effect.visible = false; return }
            const w = KWin.Workspace.activeWindow
            if (!w || !w.normalWindow || !w.moveable || !w.resizeable || w.fullScreen) return
            effect.target = w
            effect.visible = true
        }
    }

    delegate: Item {
        id: view
        focus: true
        readonly property var output: KWin.SceneView.screen
        readonly property bool home: effect.target && effect.target.output === output
        readonly property rect area: {
            const a = KWin.Workspace.clientArea(KWin.Workspace.MaximizeArea, output, KWin.Workspace.currentDesktop)
            return Qt.rect(a.x - output.geometry.x, a.y - output.geometry.y, a.width, a.height)
        }
        // The desktop stays as it is under the picker.
        Repeater {
            model: KWin.Workspace.stackingOrder.filter(w => !w.minimized && w.output === view.output)
            KWin.WindowThumbnail {
                required property var modelData
                wId: modelData.internalId
                x: modelData.frameGeometry.x - view.output.geometry.x; y: modelData.frameGeometry.y - view.output.geometry.y
                width: modelData.frameGeometry.width; height: modelData.frameGeometry.height
            }
        }
        MouseArea { anchors.fill: parent; onClicked: { effect.visible = false; effect.target = null } }
        Picker {
            id: card
            visible: view.home
            layouts: effect.layouts
            x: view.area.x + (view.area.width - width) / 2; y: view.area.y + 10
            onPicked: (l, z) => effect.pick(l, z)
            onCancelled: { effect.visible = false; effect.target = null }
            Component.onCompleted: if (view.home) focusKeys()
        }
    }
}
