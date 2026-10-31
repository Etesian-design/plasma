/*
 * The Desktop v2 Windows view (etesian-design explorations/desktop2/XWindows.vue, DesktopV2.vue) as a KWin effect.
 * Super+Tab opens the carousel (one large card) with the next window selected; while Super is held, Tab / Shift+Tab move and
 * releasing Super switches. Super+wheel (or a three-finger pinch) zooms between the phone's levels, carousel, 2, 3, 4 per row,
 * and locks the view: it then stays open as a task viewer until a window is picked or Esc.
 * Touchpad (Desktop v2 "Touchpad"): three fingers sideways minimise the window, and switch windows when none is left in front;
 * three fingers down close the window, only when SwipeDownClose is switched on (off by default).
 */
import QtQuick
import org.kde.kwin as KWinComponents

KWinComponents.SceneEffect {
    id: effect

    /** 1 = carousel, then 2, 3, 4 cards per row */
    property int level: 1
    /** Super is still held from the Super+Tab that opened the view: releasing it switches */
    property bool held: false
    /** the wheel, a pinch or a zoom button turned the switcher into a viewer that stays open */
    property bool locked: false
    property int selected: 0
    /** the switchable windows, most recently used first (snapshot taken when the view opens) */
    property var windows: []

    delegate: WindowsView {}

    function switchable(w) {
        return (w.normalWindow || w.dialog) && !w.skipSwitcher && !w.deleted
            && (w.onAllDesktops || w.desktops.indexOf(KWinComponents.Workspace.currentDesktop) >= 0)
    }
    function collect() {
        const order = KWinComponents.Workspace.stackingOrder, list = []
        for (let i = order.length - 1; i >= 0; i--) if (switchable(order[i])) list.push(order[i])
        windows = list
    }
    function show(lvl, hold, lock) {
        collect()
        if (!windows.length) return false
        level = lvl; held = hold; locked = lock
        visible = true
        return true
    }
    /** Super+Tab / Super+Shift+Tab: open with the next (previous) window selected, or move when already open */
    function forward(d) {
        if (visible) { step(d); return }
        if (show(1, true, false)) selected = windows.length > 1 ? (d > 0 ? 1 : windows.length - 1) : 0
    }
    function step(d) {
        const n = windows.length
        if (n) selected = (selected + d + n) % n
    }
    /** d > 0 = more per row (wheel down, pinch in) */
    function zoom(d) {
        level = Math.max(1, Math.min(4, level + d))
        locked = true
    }
    function activate(i) {
        const w = windows[i]
        close()
        if (w) KWinComponents.Workspace.activeWindow = w
    }
    function close() {
        held = false; locked = false
        visible = false
        windows = []
    }

    KWinComponents.ShortcutHandler {
        name: "Etesian Windows"
        text: "Etesian: Windows view (hold Super, tap Tab)"
        sequence: "Meta+Tab"
        onActivated: effect.forward(1)
    }
    KWinComponents.ShortcutHandler {
        name: "Etesian Windows (Reverse)"
        text: "Etesian: Windows view, previous window"
        sequence: "Meta+Shift+Tab"
        onActivated: effect.forward(-1)
    }

    // Pinch = Super+wheel: pinching in opens the viewer locked at 3 per row (the "4b" state) and zooms out; pinching out zooms in.
    KWinComponents.PinchGestureHandler {
        direction: KWinComponents.PinchGestureHandler.Direction.Contracting
        fingerCount: 3
        onActivated: effect.visible ? effect.zoom(1) : (effect.show(3, false, true) && (effect.selected = 0))
    }
    KWinComponents.PinchGestureHandler {
        direction: KWinComponents.PinchGestureHandler.Direction.Expanding
        fingerCount: 3
        onActivated: if (effect.visible) effect.level > 1 ? effect.zoom(-1) : effect.close()
    }

    // The N9 side swipe: the window in front goes down to the desktop; with nothing in front, the swipe brings windows back one by one.
    function sideSwipe(d) {
        const a = KWinComponents.Workspace.activeWindow
        if (a && switchable(a) && !a.minimized && a.minimizable) { a.minimized = true; return }
        collect()
        const n = windows.length
        if (!n) return
        const w = d > 0 ? windows[0] : windows[n - 1]
        windows = []
        KWinComponents.Workspace.activeWindow = w
    }
    KWinComponents.SwipeGestureHandler {
        direction: KWinComponents.SwipeGestureHandler.Direction.Left
        fingerCount: 3
        onActivated: effect.sideSwipe(-1)
    }
    KWinComponents.SwipeGestureHandler {
        direction: KWinComponents.SwipeGestureHandler.Direction.Right
        fingerCount: 3
        onActivated: effect.sideSwipe(1)
    }
    KWinComponents.SwipeGestureHandler {
        direction: KWinComponents.SwipeGestureHandler.Direction.Down
        fingerCount: 3
        onActivated: {
            const a = KWinComponents.Workspace.activeWindow
            if (effect.configuration.SwipeDownClose && a && a.closeable && switchable(a)) a.closeWindow()
        }
    }
}
