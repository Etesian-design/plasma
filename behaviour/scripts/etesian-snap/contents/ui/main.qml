/*
 * Etesian snapping (etesian-design src/shell/desktop/: geometry.ts, XZones.vue, XLayoutPicker.vue, states "drag", "snapped").
 * - Dragging a window shows the numbered zones of the current layout as cards; releasing over one snaps the window into it.
 * - Dragging to the top edge drops the layout picker (six layouts); releasing over a zone of any layout snaps there.
 *   Super+Z opens the same picker from the keyboard: that one is the etesian_snaplayouts effect (effects get the keyboard).
 * - Keyboard: Super+Left/Right move between the columns of the three-column layout, Super+Up maximises, Super+Down floats the
 *   window again at the size it had before its first snap.
 */
import QtQuick
import QtQuick.Window
import org.kde.kwin as KWin

Item {
    id: root

    readonly property int gap: 8 // geometry.ts GAP
    readonly property color accent: "#4591FF"
    /** geometry.ts LAYOUTS: zones as fractions of the work area */
    readonly property var layouts: [
        { id: "halves", label: "1/2 + 1/2", zones: [[0, 0, .5, 1], [.5, 0, .5, 1]] },
        { id: "thirds", label: "Three columns", zones: [[0, 0, 1 / 3, 1], [1 / 3, 0, 1 / 3, 1], [2 / 3, 0, 1 / 3, 1]] },
        { id: "two-thirds", label: "2/3 + 1/3", zones: [[0, 0, 2 / 3, 1], [2 / 3, 0, 1 / 3, 1]] },
        { id: "focus", label: "Focus centre", zones: [[0, 0, .25, 1], [.25, 0, .5, 1], [.75, 0, .25, 1]] },
        { id: "main-stack", label: "Main + stack", zones: [[0, 0, .5, 1], [.5, 0, .5, .5], [.5, .5, .5, .5]] },
        { id: "quarters", label: "Quarters", zones: [[0, 0, .5, .5], [.5, 0, .5, .5], [0, .5, .5, .5], [.5, .5, .5, .5]] },
    ]
    /** the layout whose zones show while dragging: three columns, or the last one picked */
    property int current: 1
    property var floating: ({}) // window id -> geometry before the first snap

    /** zoneRects(): the zones in pixels, GAP at the edges and GAP / 2 on each side between zones */
    function zones(layout, a) {
        return layouts[layout].zones.map(([fx, fy, fw, fh]) => {
            const x0 = Math.round(a.x + fx * a.width), x1 = Math.round(a.x + (fx + fw) * a.width)
            const y0 = Math.round(a.y + fy * a.height), y1 = Math.round(a.y + (fy + fh) * a.height)
            const l = x0 + (fx === 0 ? gap : gap / 2), r = x1 - (fx + fw >= 0.999 ? gap : gap / 2)
            const t = y0 + (fy === 0 ? gap : gap / 2), b = y1 - (fy + fh >= 0.999 ? gap : gap / 2)
            return Qt.rect(l, t, r - l, b - t)
        })
    }
    function area(w) { return KWin.Workspace.clientArea(KWin.Workspace.MaximizeArea, w) }
    function usable(w) { return w && w.normalWindow && w.moveable && w.resizeable && !w.fullScreen }
    function zoneOf(w, z) {
        const g = w.frameGeometry
        return z.findIndex(r => Math.abs(g.x - r.x) < 2 && Math.abs(g.y - r.y) < 2 && Math.abs(g.width - r.width) < 2 && Math.abs(g.height - r.height) < 2)
    }
    function snap(w, layout, index) {
        const key = w.internalId.toString()
        if (!(key in floating)) {
            const g = w.frameGeometry
            floating[key] = Qt.rect(g.x, g.y, g.width, g.height)
        }
        w.setMaximize(false, false)
        w.frameGeometry = zones(layout, area(w))[index]
    }
    function step(d) {
        const w = KWin.Workspace.activeWindow
        if (!usable(w)) return
        const z = zones(1, area(w)), at = zoneOf(w, z)
        snap(w, 1, at < 0 ? (d < 0 ? 0 : z.length - 1) : Math.max(0, Math.min(z.length - 1, at + d)))
    }
    function unsnap() {
        const w = KWin.Workspace.activeWindow
        if (!usable(w)) return
        w.setMaximize(false, false)
        const key = w.internalId.toString()
        if (key in floating) {
            w.frameGeometry = floating[key]
            delete floating[key]
        }
    }

    KWin.ShortcutHandler { name: "Etesian Snap Left"; text: "Etesian: snap window one column left"; sequence: "Meta+Left"; onActivated: root.step(-1) }
    KWin.ShortcutHandler { name: "Etesian Snap Right"; text: "Etesian: snap window one column right"; sequence: "Meta+Right"; onActivated: root.step(1) }
    KWin.ShortcutHandler {
        name: "Etesian Maximise"; text: "Etesian: maximise window"; sequence: "Meta+Up"
        onActivated: { const w = KWin.Workspace.activeWindow; if (root.usable(w)) w.setMaximize(true, true) }
    }
    KWin.ShortcutHandler { name: "Etesian Float"; text: "Etesian: float window again"; sequence: "Meta+Down"; onActivated: root.unsnap() }
    Connections {
        target: KWin.Workspace
        function onWindowRemoved(w) { delete root.floating[w.internalId.toString()] }
    }

    // Dragging: every window reports its interactive moves.
    Instantiator {
        model: KWin.WindowModel {}
        delegate: Connections {
            required property var window
            target: window
            function onInteractiveMoveResizeStarted() { if (window.move && root.usable(window)) overlay.startDrag(window) }
            function onInteractiveMoveResizeStepped() { if (overlay.dragging) overlay.track() }
            function onInteractiveMoveResizeFinished() { if (overlay.dragging) overlay.drop() }
        }
    }

    // While a window is dragged: an overlay over its screen with the zones, or the picker once the pointer reaches the top.
    Window {
        id: overlay
        property var target: null
        property bool dragging: false
        property bool picker: false
        /** while dragging: the zone under the pointer, in the current layout, or [layout, zone] of the picker */
        property int hot: -1
        property var pickHot: null
        property rect workArea
        // It only draws: input goes through to KWin, which is moving the window.
        flags: Qt.BypassWindowManagerHint | Qt.FramelessWindowHint | Qt.WindowTransparentForInput
        color: "transparent"

        function place(w) {
            const s = w.output.geometry
            x = s.x; y = s.y; width = s.width; height = s.height
            const a = root.area(w)
            workArea = Qt.rect(a.x - s.x, a.y - s.y, a.width, a.height)
        }
        function startDrag(w) { dragging = true; place(w); target = w; picker = false; hot = -1; pickHot = null; show() } // (visible alone does not map it)
        function hide() { target = null; dragging = false; picker = false; close() }
        /** follow the pointer: near the top edge the picker drops; elsewhere the zone under it lights up */
        function track() {
            const p = KWin.Workspace.cursorPos, lx = p.x - x, ly = p.y - y
            if (ly < workArea.y + 24) picker = true
            if (picker) {
                const g = dragPicker.mapFromItem(null, lx, ly)
                pickHot = dragPicker.contains(g) ? dragPicker.zoneAt(g) : null
                if (ly > dragPicker.y + dragPicker.height + 80) picker = false
                hot = -1
                return
            }
            const z = root.zones(root.current, workArea)
            hot = z.findIndex(r => lx >= r.x && lx < r.x + r.width && ly >= r.y && ly < r.y + r.height)
        }
        function drop() {
            const w = target
            if (picker && pickHot) { root.current = pickHot[0]; root.snap(w, pickHot[0], pickHot[1]) }
            else if (!picker && hot >= 0) root.snap(w, root.current, hot)
            hide()
        }

        // The zones (XZones): cards on a light scrim, a big light number, the hot one filled with the accent.
        Repeater {
            model: overlay.dragging && !overlay.picker ? root.zones(root.current, overlay.workArea) : []
            Rectangle {
                required property rect modelData
                required property int index
                readonly property bool isHot: index === overlay.hot
                x: modelData.x; y: modelData.y; width: modelData.width; height: modelData.height
                radius: 8
                color: isHot ? Qt.rgba(69 / 255, 145 / 255, 1, 0.42) : Qt.rgba(0, 0, 0, 0.45)
                border { width: isHot ? 3 : 2; color: isHot ? root.accent : Qt.rgba(69 / 255, 145 / 255, 1, 0.55) }
                Column {
                    anchors.centerIn: parent
                    spacing: 14
                    Text { anchors.horizontalCenter: parent.horizontalCenter; text: index + 1; color: "white"; opacity: 0.75; font { pixelSize: 120; weight: Font.Light } }
                    Rectangle {
                        visible: isHot
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: cap.implicitWidth + 28; height: 32; radius: 16; color: Qt.rgba(0, 0, 0, 0.55)
                        Text {
                            id: cap; anchors.centerIn: parent; color: "white"; font { pixelSize: 13; bold: true }
                            text: "Release to snap " + (overlay.target ? overlay.target.caption.split(/ [—–-] /).pop() : "") + " here · " + modelData.width + " × " + modelData.height
                        }
                    }
                }
            }
        }

        Picker {
            id: dragPicker
            layouts: root.layouts
            visible: overlay.picker
            dragMode: true
            hot: overlay.pickHot
            x: overlay.workArea.x + (overlay.workArea.width - width) / 2; y: overlay.workArea.y + 10
        }
    }
}
