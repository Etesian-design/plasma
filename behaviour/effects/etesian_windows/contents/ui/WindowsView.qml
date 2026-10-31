/*
 * One screen of the Windows view, laid out like XWindows.vue: the wallpaper under the home surface at 86 %, the panels (menu bar
 * and dock) left in place on top, a "Windows" header with the count and the four zoom levels, the cards, and the hint at the bottom.
 * Card geometry follows XWindows.vue: level 1 is a row of cards bottom-aligned on one line with the selected card centred;
 * levels 2-4 are a grid whose cells are 0.62 as tall as wide. Every card keeps its window's aspect ratio.
 */
import QtQuick
import org.kde.kwin as KWinComponents
import org.kde.kirigami as Kirigami

Item {
    id: view
    focus: true

    readonly property var output: KWinComponents.SceneView.screen
    readonly property rect area: {
        const a = KWinComponents.Workspace.clientArea(KWinComponents.Workspace.MaximizeArea, output, KWinComponents.Workspace.currentDesktop)
        return Qt.rect(a.x - output.geometry.x, a.y - output.geometry.y, a.width, a.height)
    }
    readonly property color accent: "#4591FF"       // --hd-color-accent-default
    readonly property color fgSecondary: "#C8C8C8"  // --hd-surface-home-fg-secondary
    readonly property color divider: Qt.rgba(1, 1, 1, 0.16)
    readonly property int topY: 76; readonly property int titleH: 34; readonly property int pad: 56 // XWindows.vue TOP, TITLE, PAD
    readonly property int duration: 350             // --hd-motion-duration-slow

    /** [{x, y, w, h, side}] for effect.windows, in view coordinates */
    readonly property var cards: {
        const wins = effect.windows, n = effect.level, x0 = area.x + pad, avail = area.width - 2 * pad, y0 = area.y + topY
        if (!wins.length) return []
        const fit = (w, bw, bh) => { const g = w.frameGeometry, s = Math.min(bw / g.width, bh / g.height); return { w: Math.round(g.width * s), h: Math.round(g.height * s) } }
        if (n === 1) {
            const ch = area.height - topY - titleH - 90, cw = Math.min(Math.round(ch * 1.5), avail - 420), G = 64
            const fits = wins.map(w => fit(w, cw, ch)), sel = Math.min(effect.selected, wins.length - 1), xs = []
            xs[sel] = x0 + avail / 2 - fits[sel].w / 2
            for (let i = sel + 1; i < fits.length; i++) xs[i] = xs[i - 1] + fits[i - 1].w + G
            for (let i = sel - 1; i >= 0; i--) xs[i] = xs[i + 1] - G - fits[i].w
            return fits.map((f, i) => ({ x: Math.round(xs[i]), y: y0 + ch - f.h, w: f.w, h: f.h, side: i - sel }))
        }
        const gap = n === 2 ? 40 : n === 3 ? 32 : 26
        const cw = (avail - gap * (n - 1)) / n, ch = Math.round(cw * 0.62), rowH = ch + titleH + gap
        // rows past the bottom scroll up so the selected card stays in view
        const rows = Math.max(1, Math.floor((area.height - topY - 70 + gap) / rowH))
        const first = Math.max(0, Math.floor(effect.selected / n) - rows + 1)
        return wins.map((w, i) => {
            const c = i % n, r = Math.floor(i / n) - first, f = fit(w, cw, ch)
            return { x: Math.round(x0 + c * (cw + gap) + (cw - f.w) / 2), y: y0 + r * rowH + (ch - f.h), w: f.w, h: f.h, side: 0 }
        })
    }

    /** "Document — App" captions (the KDE convention) split into the app name and the window title */
    function names(w) {
        const parts = w.caption.split(/ [—–-] /)
        if (parts.length > 1) return { app: parts[parts.length - 1], title: parts.slice(0, -1).join(" — ") }
        const rc = w.resourceClass || ""
        return { app: rc ? rc.charAt(0).toUpperCase() + rc.slice(1) : w.caption, title: rc ? w.caption : "" }
    }

    Keys.onPressed: (e) => {
        if (e.key === Qt.Key_Tab || e.key === Qt.Key_Right) effect.step(1)
        else if (e.key === Qt.Key_Backtab || e.key === Qt.Key_Left) effect.step(-1)
        else if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter || e.key === Qt.Key_Space) effect.activate(effect.selected)
        else if (e.key === Qt.Key_Escape) effect.close()
        else return
        e.accepted = true
    }
    // Releasing Super ends a quick switch, unless the view was locked open.
    Keys.onReleased: (e) => {
        if ((e.key === Qt.Key_Meta || e.key === Qt.Key_Super_L || e.key === Qt.Key_Super_R) && effect.held) {
            effect.held = false
            if (!effect.locked) effect.activate(effect.selected)
            e.accepted = true
        }
    }

    KWinComponents.DesktopBackground {
        activity: KWinComponents.Workspace.currentActivity
        desktop: KWinComponents.Workspace.currentDesktop
        outputName: view.output.name
    }
    Rectangle { anchors.fill: parent; color: Qt.rgba(0, 0, 0, 0.86) } // --hd-surface-home at 86 %

    // Super+wheel zooms (and locks); the plain wheel moves through the carousel. KWin hands effects the wheel as its axis value:
    // 15 per notch, positive = wheel down. Touchpads send smaller steps, so they count once they add up to a notch.
    WheelHandler {
        property real acc: 0
        acceptedModifiers: Qt.KeyboardModifierMask
        onWheel: (e) => {
            acc += e.angleDelta.y
            if (Math.abs(acc) < 15) return
            const d = acc > 0 ? 1 : -1  // wheel down = more per row / next window
            acc = 0
            if (e.modifiers & (Qt.MetaModifier | Qt.ControlModifier)) effect.zoom(d)
            else if (effect.level === 1) { effect.step(d); effect.locked = true }
        }
    }
    MouseArea { anchors.fill: parent; onClicked: effect.close() } // a click on the empty backdrop closes, like Esc

    // Header: "Windows", the count and the level, the zoom buttons on the right.
    Row {
        id: head
        x: view.area.x + view.pad; y: view.area.y + 20
        width: view.area.width - 2 * view.pad
        spacing: 16
        Text {
            text: "Windows"; color: "white"
            font { pixelSize: 36; weight: Font.Light }
        }
        Text {
            anchors.verticalCenter: parent.verticalCenter
            width: head.width - x - zoomRow.width
            text: effect.windows.length + " open · " + ["One at a time", "2 per row", "3 per row", "4 per row"][effect.level - 1]
            color: view.fgSecondary; font.pixelSize: 13
        }
        Row {
            id: zoomRow
            anchors.verticalCenter: parent.verticalCenter
            spacing: 2
            Repeater {
                model: 4
                Item {
                    id: zb
                    readonly property int lvl: index + 1
                    readonly property bool on: effect.level === lvl
                    width: 36; height: 36
                    Squircle {
                        anchors.centerIn: parent; size: 34
                        visible: zb.on || zbMouse.containsMouse
                        fill: zb.on ? view.accent : Qt.rgba(1, 1, 1, 0.12)
                        fillFrom: zb.on ? Qt.lighter(view.accent, 1.3) : fill
                    }
                    // the level drawn as its cards: one wide, or n narrow
                    Row {
                        anchors.centerIn: parent
                        spacing: zb.lvl === 1 ? 0 : 1.5
                        Repeater {
                            model: zb.lvl
                            Rectangle {
                                width: zb.lvl === 1 ? 12 : 20 / zb.lvl - 1.5; height: zb.lvl === 1 ? 12 : 8; radius: 1.5
                                color: zb.on ? "white" : view.fgSecondary
                            }
                        }
                    }
                    MouseArea { id: zbMouse; anchors.fill: parent; hoverEnabled: true; onClicked: { effect.level = zb.lvl; effect.locked = true } }
                }
            }
        }
    }

    Repeater {
        model: effect.windows
        delegate: Item {
            id: card
            required property var modelData
            required property int index
            readonly property var r: view.cards[index] || { x: 0, y: 0, w: 0, h: 0, side: 0 }
            readonly property bool current: index === effect.selected
            readonly property var n: view.names(modelData)
            x: r.x; y: r.y; width: r.w; height: r.h + 10 + 24
            opacity: effect.level === 1 && r.side !== 0 ? 0.5 : 1
            Behavior on x { NumberAnimation { duration: view.duration; easing.type: Easing.OutCubic } }
            Behavior on y { NumberAnimation { duration: view.duration; easing.type: Easing.OutCubic } }
            Behavior on width { NumberAnimation { duration: view.duration; easing.type: Easing.OutCubic } }
            Behavior on opacity { NumberAnimation { duration: view.duration } }

            // the selected card gets the 3 px accent ring, the others a hairline
            Rectangle {
                x: card.current ? -3 : -1; y: x; width: card.width - 2 * x; height: card.r.h - 2 * x
                radius: 8 - x; color: "#1E1E1E"
                border { width: card.current ? 3 : 1; color: card.current ? view.accent : view.divider }
            }
            KWinComponents.WindowThumbnail {
                id: thumb
                wId: card.modelData.internalId
                width: card.width; height: card.r.h
                scale: hover.containsMouse ? 1.015 : 1
                Behavior on scale { NumberAnimation { duration: 130 } }
            }
            Row {
                y: card.r.h + 10; height: 24; spacing: 8
                width: Math.min(implicitWidth, card.width)
                x: effect.level === 1 ? (card.width - width) / 2 : 0 // centred under the big card, left-aligned in the grid
                clip: true
                Squircle {
                    size: 20; fill: "#3A3A3A"; anchors.verticalCenter: parent.verticalCenter
                    Kirigami.Icon { anchors.centerIn: parent; width: 14; height: 14; source: card.modelData.icon }
                }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: card.n.app; color: "white"
                    font { pixelSize: effect.level === 1 ? 16 : 13; bold: true }
                }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: card.n.title; color: view.fgSecondary; elide: Text.ElideRight
                    width: Math.max(0, Math.min(implicitWidth, card.width - x))
                    font.pixelSize: effect.level === 1 ? 16 : 13
                }
            }
            MouseArea {
                id: hover
                anchors.fill: parent
                hoverEnabled: true
                onEntered: if (effect.level > 1 || card.r.side === 0) effect.selected = card.index
                onClicked: effect.activate(card.index)
            }
        }
    }

    // The panels stay where they are, above the view (the dock and menu bar sit over XWindows in the design).
    Repeater {
        model: KWinComponents.Workspace.stackingOrder.filter(w => w.dock)
        KWinComponents.WindowThumbnail {
            required property var modelData
            wId: modelData.internalId
            x: modelData.frameGeometry.x - view.output.geometry.x; y: modelData.frameGeometry.y - view.output.geometry.y
            width: modelData.frameGeometry.width; height: modelData.frameGeometry.height
        }
    }

    // Bottom hint (DesktopV2.vue .x-switchhint): how to switch while Super is held, or that the viewer is locked open.
    Rectangle {
        anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom; bottomMargin: 22 }
        width: hint.implicitWidth + 32; height: 40; radius: 8
        color: Qt.rgba(20 / 255, 20 / 255, 20 / 255, 0.97)    // --hd-surface-overlay
        border { width: 1; color: view.divider }
        Row {
            id: hint
            anchors.centerIn: parent
            spacing: 8
            readonly property bool quick: effect.held && !effect.locked
            component Hint: Text { anchors.verticalCenter: parent.verticalCenter; color: view.fgSecondary; font.pixelSize: 13 }
            component Strong: Text { anchors.verticalCenter: parent.verticalCenter; color: "white"; font { pixelSize: 13; bold: true } }
            KeyCap { visible: hint.quick; text: "Super"; anchors.verticalCenter: parent.verticalCenter }
            Hint { visible: hint.quick; text: "held ·" }
            Strong { visible: hint.quick; text: "Release Super to switch" }
            Hint { visible: hint.quick; text: "·" }
            KeyCap { visible: hint.quick; text: "Tab"; anchors.verticalCenter: parent.verticalCenter }
            Hint { visible: hint.quick; text: "next ·" }
            KeyCap { visible: hint.quick; text: "Shift+Tab"; anchors.verticalCenter: parent.verticalCenter }
            Hint { visible: hint.quick; text: "back ·" }
            Strong { visible: hint.quick; text: "Scroll to keep open" }
            Kirigami.Icon { visible: !hint.quick; source: "object-locked"; width: 14; height: 14; color: "white"; isMask: true; anchors.verticalCenter: parent.verticalCenter }
            Strong { visible: !hint.quick; text: "Viewer kept open"; font.bold: false }
            Hint { visible: !hint.quick; text: "· pick a window or" }
            KeyCap { visible: !hint.quick; text: "Esc"; anchors.verticalCenter: parent.verticalCenter }
        }
    }
}
