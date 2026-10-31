/*
 * The Desktop v2 dock (etesian-design explorations/desktop2/XDock.vue, XDockSettings.vue), after the launcher widget:
 * separator | pinned and running apps | separator | recycle bin, always last. Every item is a squircle: each app a lit squircle
 * in its icon's own colour with the icon on it, the bin a faint squircle. Running apps get a small dot on the screen-edge side,
 * the active one a larger accent dot. Hover and the active app get the pressed squircle behind them.
 * Right-click → Edit dock: a dashed accent outline, × badges on the pins and the bin, a move handle (drag it to any screen edge),
 * a banner at the top and the settings popover. Every extra is opt-in there: full-height panel, window previews on hover, clock,
 * battery, icon size, auto-hide or dodge, position.
 */
import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.kirigami as Kirigami
import org.kde.taskmanager as TaskManager
import "etesianicons.js" as EtesianIcons
import org.kde.plasma.plasma5support as P5Support

PlasmoidItem {
    id: root

    readonly property bool vertical: Plasmoid.formFactor === PlasmaCore.Types.Vertical
    readonly property var cfg: Plasmoid.configuration
    readonly property int icon: cfg.iconSize                            // XDock size (44)
    readonly property int cell: icon + 8                                // .x-dock__item box
    readonly property color accent: "#4591FF"
    readonly property color pressed: Qt.rgba(1, 1, 1, 0.12)            // --hd-c-pressed on dark surfaces
    readonly property color divider: Qt.rgba(1, 1, 1, 0.16)
    readonly property color warning: "#E8553A"                          // --hd-color-palette-warning (× badges)
    /** which side the running dot sits on: the screen edge the dock is attached to */
    readonly property int edge: Plasmoid.location
    readonly property string position: edge === PlasmaCore.Types.RightEdge ? "right" : edge === PlasmaCore.Types.TopEdge ? "top"
        : edge === PlasmaCore.Types.BottomEdge ? "bottom" : "left"
    property bool editing: false

    preferredRepresentation: fullRepresentation
    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground
    /** the strip's length: separator, apps, separator and the bin/clock/battery, the edit handle and gear; 4 px between all */
    readonly property bool tail: cfg.trash || cfg.clock || cfg.battery
    readonly property int length: {
        const parts = [1, ...Array(tasks.count).fill(cell)]
        if (tail) parts.push(1)
        if (cfg.trash) parts.push(cell)
        if (cfg.clock) parts.push(cell)
        if (cfg.battery && percent >= 0) parts.push(cell)
        if (editing) parts.push(vertical ? 24 : cell, 36)
        return parts.reduce((a, b) => a + b, 0) + 4 * (parts.length - 1)
    }
    Layout.preferredWidth: vertical ? cell : length
    Layout.preferredHeight: vertical ? length : cell
    Layout.minimumWidth: Layout.preferredWidth; Layout.minimumHeight: Layout.preferredHeight

    TaskManager.VirtualDesktopInfo { id: desktopInfo }
    TaskManager.ActivityInfo { id: activityInfo }
    TaskManager.TasksModel {
        id: tasks
        groupMode: TaskManager.TasksModel.GroupApplications
        sortMode: TaskManager.TasksModel.SortManual
        launchInPlace: true
        separateLaunchers: false
        launcherList: root.cfg.launchers
        virtualDesktop: desktopInfo.currentDesktop
        activity: activityInfo.currentActivity
        filterByVirtualDesktop: true
        filterByActivity: true
        onLauncherListChanged: root.cfg.launchers = launcherList
    }

    // The panel the dock sits in is changed through Plasma's own desktop scripting (position, length, hiding, size).
    P5Support.DataSource { id: exec; engine: "executable"; onNewData: (s) => disconnectSource(s) }
    function panelScript(body) {
        const js = 'panels().filter(p => p.widgets("org.etesian.dock").length).forEach(p => { ' + body + ' })'
        exec.connectSource("dbus-send --session --type=method_call --dest=org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript string:'"
            + js.replace(/'/g, "'\\''") + "'")
    }
    function setPosition(p) { if (["left", "right", "top", "bottom"].indexOf(p) >= 0) panelScript('p.location = "' + p + '"') }
    function setStyle(v) {
        cfg.dockStyle = v
        panelScript(v === "panel" ? 'p.lengthMode = "fill"; p.floating = false' : 'p.lengthMode = "fit"; p.floating = true')
    }
    function setVisibility(v) {
        cfg.visibility = v
        panelScript('p.hiding = "' + ({ always: "none", autohide: "autohide", dodge: "dodgewindows" })[v] + '"')
    }
    function setSize(s) { cfg.iconSize = s; panelScript("p.height = " + (s + 24)) }
    function setLauncherButton(on) {
        panelScript(on ? 'if (!p.widgets("org.etesian.launcher").length) { const w = p.addWidget("org.etesian.launcher"); w.index = 0 }'
                       : 'p.widgets("org.etesian.launcher").forEach(w => w.remove())')
    }
    function setWidget(id, on) {
        if (id === "launcher") setLauncherButton(on)
        else cfg[id] = on
    }

    // Battery for the optional battery widget.
    P5Support.DataSource { id: power; engine: "powermanagement"; connectedSources: root.cfg.battery ? ["Battery"] : [] }
    readonly property int percent: power.data["Battery"] && power.data["Battery"]["Has Battery"] ? power.data["Battery"]["Percent"] : -1
    property date now: new Date()
    Timer { interval: 10000; running: root.cfg.clock; repeat: true; onTriggered: root.now = new Date() }

    fullRepresentation: Item {
        // Right-click anywhere on the dock: Edit dock (states.ts dock-edit).
        MouseArea {
            anchors.fill: parent; acceptedButtons: Qt.RightButton
            onClicked: root.editing = true
        }
        Rectangle { // the dashed accent outline of edit mode (drawn solid: QML has no dashed border)
            visible: root.editing
            anchors { fill: strip; margins: -5 }
            radius: 10; color: "transparent"; border { width: 2; color: root.accent }
        }
        Grid {
            id: strip
            anchors.centerIn: parent
            columns: root.vertical ? 1 : -1
            rows: root.vertical ? -1 : 1
            spacing: 4
            horizontalItemAlignment: Grid.AlignHCenter
            verticalItemAlignment: Grid.AlignVCenter

            // The launcher (org.etesian.launcher) sits just before this widget; the separator after it starts here.
            Divider {}

            Repeater {
                model: tasks
                DockButton {
                    id: task
                    required property var model
                    required property int index
                    tip: root.cfg.previews && !model.IsLauncher ? "" : model.IsLauncher ? model.display : model.AppName + " · running"
                    active: model.IsActive === true
                    removable: model.HasLauncher === true
                    AppTile { anchors.centerIn: parent; source: task.model.decoration; own: EtesianIcons.has(task.model.AppId || "") || EtesianIcons.has(String(task.model.LauncherUrlWithoutIcon || "")) }
                    Rectangle {
                        visible: !task.model.IsLauncher
                        readonly property int d: task.active ? 5 : 4
                        width: d; height: d; radius: d / 2
                        color: task.active ? root.accent : "#C8C8C8"
                        x: root.edge === PlasmaCore.Types.LeftEdge ? -6 : root.edge === PlasmaCore.Types.RightEdge ? parent.width + 6 - d : (parent.width - d) / 2
                        y: root.vertical ? (parent.height - d) / 2 : root.edge === PlasmaCore.Types.TopEdge ? -6 : parent.height + 6 - d
                    }
                    onClicked: {
                        const i = tasks.makeModelIndex(index)
                        if (model.IsLauncher) tasks.requestActivate(i)
                        else if (model.IsActive) tasks.requestToggleMinimized(i)
                        else tasks.requestActivate(i)
                    }
                    onMiddleClicked: tasks.requestNewInstance(tasks.makeModelIndex(index))
                    onRemoved: tasks.requestRemoveLauncher(model.LauncherUrlWithoutIcon)
                    // scroll to cycle the app's windows (the preview's "scroll to cycle")
                    onScrolled: (d) => {
                        const n = model.ChildCount || 0
                        if (n < 2) { if (!model.IsLauncher) tasks.requestActivate(tasks.makeModelIndex(index)); return }
                        task.child = (task.child + (d > 0 ? 1 : n - 1)) % n
                        tasks.requestActivate(tasks.makeModelIndex(index, task.child))
                    }
                    property int child: 0
                    hoverPreview: root.cfg.previews && !model.IsLauncher && !root.editing
                    previewName: model.AppName || model.display || ""
                    previewWinId: model.WinIdList && model.WinIdList.length ? model.WinIdList[0] : ""
                    previewIcon: model.decoration
                    previewSize: model.Geometry ? Qt.size(model.Geometry.width, model.Geometry.height) : Qt.size(16, 10)
                }
            }

            Divider { visible: root.tail }
            // Recycle bin, always last of the apps.
            DockButton {
                visible: root.cfg.trash
                tip: "Recycle bin"
                removable: true
                Squircle {
                    anchors.centerIn: parent; size: root.icon; fill: Qt.rgba(1, 1, 1, 0.10)
                    Kirigami.Icon { anchors.centerIn: parent; width: root.icon / 2; height: width; source: "user-trash-symbolic"; color: "white"; isMask: true }
                }
                onClicked: Qt.openUrlExternally("trash:/")
                onRemoved: root.cfg.trash = false
            }
            // Clock widget (.x-dock__clock): hours over minutes, bold, then the day.
            Item {
                visible: root.cfg.clock
                width: root.cell; height: root.cell
                Column {
                    anchors.centerIn: parent; spacing: 0
                    Text { anchors.horizontalCenter: parent.horizontalCenter; text: Qt.formatTime(root.now, "hh"); color: "white"; font { pixelSize: root.icon * 0.36; bold: true } }
                    Text { anchors.horizontalCenter: parent.horizontalCenter; text: Qt.formatTime(root.now, "mm"); color: "white"; font { pixelSize: root.icon * 0.36; bold: true } }
                    Text { anchors.horizontalCenter: parent.horizontalCenter; text: Qt.formatDate(root.now, "ddd d"); color: "#C8C8C8"; font.pixelSize: 10 }
                }
            }
            // Battery widget.
            Item {
                visible: root.cfg.battery && root.percent >= 0
                width: root.cell; height: root.cell
                Column {
                    anchors.centerIn: parent; spacing: 2
                    Kirigami.Icon { anchors.horizontalCenter: parent.horizontalCenter; width: root.icon * 0.45; height: width; color: "white"; isMask: true
                        source: "battery-" + String(Math.min(100, Math.round(root.percent / 10) * 10)).padStart(3, "0") + "-symbolic" }
                    Text { anchors.horizontalCenter: parent.horizontalCenter; text: root.percent + "%"; color: "white"; font.pixelSize: 11 }
                }
            }
            // Edit mode: the move handle (three bars) and the settings gear.
            Item {
                id: handle
                visible: root.editing
                width: root.cell; height: root.vertical ? 24 : root.cell
                Column {
                    anchors.centerIn: parent; spacing: 3
                    Repeater { model: 3; Rectangle { width: 18; height: 2; radius: 1; color: "#C8C8C8" } }
                }
                MouseArea {
                    anchors.fill: parent; cursorShape: Qt.SizeAllCursor
                    PlasmaCore.ToolTipArea { anchors.fill: parent; mainText: "Drag to any screen edge"; location: Plasmoid.location }
                    onReleased: (e) => {
                        const g = mapToGlobal(e.x, e.y), s = Plasmoid.containment.screenGeometry
                        const d = { left: g.x - s.x, right: s.x + s.width - g.x, top: g.y - s.y, bottom: s.y + s.height - g.y }
                        const p = Object.keys(d).reduce((a, b) => d[a] <= d[b] ? a : b)
                        if (p !== root.position) root.setPosition(p)
                    }
                }
            }
            MouseArea {
                visible: root.editing
                width: 36; height: 36
                onClicked: settings.visible = !settings.visible
                Squircle { anchors.centerIn: parent; size: 32; fill: root.accent
                    Kirigami.Icon { anchors.centerIn: parent; width: 16; height: 16; source: "configure-symbolic"; color: "white"; isMask: true } }
            }
        }
    }

    // Edit dock banner, top centre (DesktopV2 .x-editbanner).
    PlasmaCore.Dialog {
        id: banner
        visible: root.editing
        location: PlasmaCore.Types.Floating
        flags: Qt.WindowStaysOnTopHint | Qt.WindowDoesNotAcceptFocus
        type: PlasmaCore.Dialog.Notification
        onVisibleChanged: if (visible) {
            const s = Plasmoid.containment.screenGeometry
            x = s.x + (s.width - mainItem.width) / 2; y = s.y + 44
        }
        mainItem: Row {
            spacing: 10; height: 22
            Kirigami.Icon { width: 18; height: 18; source: "document-edit-symbolic"; color: "white"; isMask: true; anchors.verticalCenter: parent.verticalCenter }
            Text { text: "Edit dock"; color: "white"; font { pixelSize: 13; bold: true } anchors.verticalCenter: parent.verticalCenter }
            Text { text: "Drag the handle to any screen edge · × removes · everything else is in the settings"; color: "#C8C8C8"; font.pixelSize: 13; anchors.verticalCenter: parent.verticalCenter }
            Rectangle { width: esc.implicitWidth + 12; height: 20; radius: 4; color: Qt.rgba(1, 1, 1, 0.14); anchors.verticalCenter: parent.verticalCenter
                Text { id: esc; anchors.centerIn: parent; text: "Esc"; color: "white"; font { pixelSize: 11; bold: true } } }
            Text { text: "Done"; color: "white"; font.pixelSize: 13; anchors.verticalCenter: parent.verticalCenter }
        }
    }

    // The settings popover, next to the dock.
    PlasmaCore.Dialog {
        id: settings
        visible: root.editing
        visualParent: root
        location: Plasmoid.location
        hideOnWindowDeactivate: false
        flags: Qt.WindowStaysOnTopHint
        onVisibleChanged: if (visible) { requestActivate(); keys.forceActiveFocus() }
        mainItem: FocusScope {
            id: keys
            width: panelSettings.width; height: panelSettings.height
            focus: true
            Keys.onEscapePressed: root.editing = false
            DockSettings {
                id: panelSettings
                style: root.cfg.dockStyle
                position: root.position
                size: root.icon
                visibility: root.cfg.visibility
                widgets: [
                    { id: "launcher", label: "Launcher button (first)", icon: "view-app-grid-symbolic", on: true },
                    { id: "previews", label: "Window previews on hover", icon: "window-symbolic", on: root.cfg.previews },
                    { id: "trash", label: "Recycle bin (last)", icon: "user-trash-symbolic", on: root.cfg.trash },
                    { id: "clock", label: "Clock", icon: "clock-symbolic", on: root.cfg.clock },
                    { id: "battery", label: "Battery", icon: "battery-symbolic", on: root.cfg.battery },
                ]
                onStyleSet: (v) => root.setStyle(v)
                onPositionSet: (v) => root.setPosition(v)
                onSizeSet: (v) => root.setSize(v)
                onVisibilitySet: (v) => root.setVisibility(v)
                onWidgetSet: (id, on) => root.setWidget(id, on)
                onAddWidgets: { root.editing = false; Plasmoid.containment.internalAction("add widgets")?.trigger() }
                onDone: root.editing = false
            }
        }
    }

    /** a dock slot: the pressed squircle on hover or when active, a tooltip, left and middle clicks, wheel; × in edit mode */
    component DockButton: Item {
        id: btn
        property string tip
        property bool active: false
        property bool removable: false
        property bool hoverPreview: false
        property string previewName
        property var previewWinId
        property size previewSize
        property var previewIcon
        signal clicked()
        signal middleClicked()
        signal removed()
        signal scrolled(int delta)
        width: root.cell; height: root.cell
        Squircle { anchors.centerIn: parent; size: root.cell; fill: root.pressed; visible: mouse.containsMouse || btn.active; z: -1 }
        PlasmaCore.ToolTipArea { anchors.fill: parent; mainText: btn.tip; active: btn.tip !== ""; location: Plasmoid.location }
        MouseArea {
            id: mouse
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
            onClicked: (e) => e.button === Qt.RightButton ? (root.editing = true) : e.button === Qt.MiddleButton ? btn.middleClicked() : btn.clicked()
            onWheel: (w) => { if (Math.abs(w.angleDelta.y) >= 60) btn.scrolled(w.angleDelta.y < 0 ? 1 : -1) }
        }
        // × badge (.x-dock__rm): a small warning squircle at the top right
        MouseArea {
            visible: root.editing && btn.removable
            x: parent.width - 14; y: -4; width: 18; height: 18; z: 2
            onClicked: btn.removed()
            Squircle { anchors.fill: parent; size: 18; fill: root.warning
                Text { anchors.centerIn: parent; text: "×"; color: "white"; font { pixelSize: 13; bold: true } } }
        }
        // Window preview on hover (.x-dock__peek): the live window, the app in bold, its size and the hint.
        PlasmaCore.Dialog {
            visible: btn.hoverPreview && mouse.containsMouse && btn.previewWinId !== ""
            visualParent: btn
            location: Plasmoid.location
            type: PlasmaCore.Dialog.Tooltip
            flags: Qt.WindowDoesNotAcceptFocus
            mainItem: Column {
                spacing: 4
                width: Math.max(live.width, 280); height: implicitHeight
                Loader { id: live; source: "Preview.qml"; onLoaded: { item.winId = Qt.binding(() => btn.previewWinId); item.windowSize = Qt.binding(() => btn.previewSize); item.icon = Qt.binding(() => btn.previewIcon) } }
                Text { topPadding: 6; text: btn.previewName; color: "white"; font { pixelSize: 22; weight: Font.Light } }
                Text { text: btn.previewSize.width + " × " + btn.previewSize.height + " · click to focus, scroll to cycle"; color: "#C8C8C8"; font.pixelSize: 12 }
            }
        }
    }

    /** an app as a lit squircle: its icon's dominant colour, lighter at the top, with the icon on it */
    component AppTile: Squircle {
        id: tile
        property var source
        /** the icon theme already draws this app as a lit squircle: show it whole, without the tile behind */
        property bool own: false
        size: root.icon
        fill: own ? "transparent" : colors.dominant.valid && colors.dominant.a > 0.5 ? Qt.darker(colors.dominant, 1.25) : "#3A3A3A"
        fillFrom: own ? "transparent" : colors.dominant.valid && colors.dominant.a > 0.5 ? Qt.lighter(colors.dominant, 1.15) : "#5A5A5A"
        Kirigami.ImageColors { id: colors; source: tile.source; Component.onCompleted: update(); onSourceChanged: update() }
        Kirigami.Icon { anchors.centerIn: parent; width: tile.own ? root.icon : Math.round(root.icon * 0.66); height: width; source: tile.source; roundToIconSize: !tile.own }
    }

    component Divider: Rectangle {
        width: root.vertical ? root.cell * 0.7 : 1
        height: root.vertical ? 1 : root.cell * 0.7
        color: root.divider
    }
}
