/*
 * The Overview, the main menu (etesian-design src/shell/parts/XOverview.vue).
 * In the dock: the accent squircle with the grid glyph, first item. Tapping Super (Plasma's launcher key) or clicking it opens
 * the full-screen Overview under the menu bar, in the N9 home order:
 *   the phone's Events view on the left (the same as the Events sidebar: date, time and weather, notifications, calendar, feeds),
 *   the open windows as live pictures in the middle (two per row, a close squircle on hover, no title), and the apps on the right
 *   (type to search, 5 columns of 54 px squircles).
 * Typing goes to the search; Tab moves between the columns, the arrows within one, Enter opens, Ctrl+W closes the picked window,
 * Esc or Super closes the Overview. The compact search panel is a separate addition: Super+Space (org.etesian.search).
 */
import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import QtQuick.Window
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.kirigami as Kirigami
import org.kde.plasma.plasma5support as P5Support
import org.kde.taskmanager as TaskManager
import "etesianicons.js" as EtesianIcons

PlasmoidItem {
    id: root

    readonly property color accent: "#4591FF"
    readonly property color fgSecondary: "#C8C8C8"
    readonly property color divider: Qt.rgba(1, 1, 1, 0.16)
    readonly property color pressed: Qt.rgba(1, 1, 1, 0.12)
    readonly property int cell: 52

    preferredRepresentation: fullRepresentation
    activationTogglesExpanded: false
    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground
    Plasmoid.icon: "view-app-grid-symbolic"
    Layout.preferredWidth: cell; Layout.preferredHeight: cell
    Layout.minimumWidth: cell; Layout.minimumHeight: cell

    Connections {
        target: Plasmoid
        function onActivated() { overview.visible ? overview.close() : overview.open() }
    }

    // ---- apps: every installed app, read by contents/code/apps.sh ("id<TAB>name<TAB>icon" per line) when the Overview opens
    property var allApps: []
    readonly property string listScript: decodeURIComponent(Qt.resolvedUrl("../code/apps.sh").toString().replace(/^file:\/\//, ""))
    P5Support.DataSource {
        id: exec
        engine: "executable"
        onNewData: (source, data) => {
            if (source.indexOf("apps.sh") >= 0) {
                root.allApps = (data.stdout || "").split("\n").filter(l => l).map(l => {
                    const [id, name, icon] = l.split("\t")
                    return { id: id, name: name, icon: icon || "application-x-executable" }
                }).sort((a, b) => a.name.localeCompare(b.name))
            }
            disconnectSource(source)
        }
    }
    function refresh() { exec.connectSource("sh '" + listScript.replace(/'/g, "'\\''") + "'") }
    Component.onCompleted: refresh()

    property string query: ""
    readonly property var matches: {
        const q = query.trim().toLowerCase()
        return q ? allApps.filter(a => a.name.toLowerCase().indexOf(q) >= 0) : allApps
    }
    // Started through a task model, which hands the app an activation token so it comes up focused.
    // (Plasma's own app model, org.kde.plasma.private.kicker, crashes Plasma 6.8 in a third-party widget.)
    TaskManager.TasksModel { id: starter; filterByVirtualDesktop: false; filterByActivity: false }
    function launch(app) {
        overview.close()
        if (!/^[\w.+-]+\.desktop$/.test(app.id)) return
        starter.launcherList = ["applications:" + app.id]
        for (let i = 0; i < starter.count; i++) {
            const idx = starter.makeModelIndex(i)
            if (starter.data(idx, TaskManager.AbstractTasksModel.IsLauncher)) { starter.requestNewInstance(idx); break }
        }
    }

    // ---- windows: one card per window, most recent first
    TaskManager.VirtualDesktopInfo { id: desktopInfo }
    TaskManager.ActivityInfo { id: activityInfo }
    TaskManager.TasksModel {
        id: windows
        groupMode: TaskManager.TasksModel.GroupDisabled
        sortMode: TaskManager.TasksModel.SortLastActivated
        filterByVirtualDesktop: true; virtualDesktop: desktopInfo.currentDesktop
        filterByActivity: true; activity: activityInfo.currentActivity
        filterNotMinimized: false
        launchInPlace: false
    }

    // The dock button.
    fullRepresentation: Item {
        PlasmaCore.ToolTipArea { anchors.fill: parent; mainText: "Overview (Super)"; location: Plasmoid.location }
        Squircle { anchors.centerIn: parent; size: root.cell; fill: root.pressed; visible: mouse.containsMouse || overview.visible }
        Squircle {
            anchors.centerIn: parent; size: 44
            fill: root.accent; fillFrom: Qt.lighter(root.accent, 1.25)
            Kirigami.Icon { anchors.centerIn: parent; width: 22; height: 22; source: "view-app-grid-symbolic"; color: "white"; isMask: true }
        }
        MouseArea { id: mouse; anchors.fill: parent; hoverEnabled: true; onClicked: Plasmoid.activated() }
    }

    // ---- the Overview: full screen under the menu bar (.x-ov: 420 px | windows | 600 px, the home surface at 92 %)
    // A Plasma dialog, not a plain window: it stays out of the task list and is placed over the dock.
    PlasmaCore.Dialog {
        id: overview
        location: PlasmaCore.Types.Floating
        // the standard background is what makes KWin blur the windows behind (.x-ov: backdrop-filter blur 18px)
        backgroundHints: PlasmaCore.Types.StandardBackground
        hideOnWindowDeactivate: true
        flags: Qt.WindowStaysOnTopHint | Qt.FramelessWindowHint
        visible: false
        /** which column has the keyboard: 0 events, 1 windows, 2 apps */
        property int column: 2
        function open() {
            root.query = ""; column = 2
            root.refresh()
            const s = Plasmoid.containment.screenGeometry
            const a = Plasmoid.containment.availableScreenRect // relative to the screen; its top is the menu bar's bottom
            const top = a && a.y > 0 ? a.y : 32
            // the frame's margins sit outside the content: grow past the screen edges by them
            body.width = s.width - margins.left - margins.right; body.height = s.height - top - margins.top - margins.bottom
            x = s.x; y = s.y + top
            visible = true
            requestActivate()
            search.forceActiveFocus()
        }
        function close() { visible = false }

        mainItem: FocusScope {
            id: body
            width: 1600; height: 900
            focus: true
            function toColumn(c) {
                overview.column = c
                if (c === 2) search.forceActiveFocus(); else if (c === 1) winGrid.forceActiveFocus(); else feed.forceActiveFocus()
            }
            Keys.onPressed: (e) => {
                if (e.key === Qt.Key_Escape || e.key === Qt.Key_Meta || e.key === Qt.Key_Super_L) { overview.close(); e.accepted = true }
                else if (e.key === Qt.Key_Tab || e.key === Qt.Key_Backtab) { toColumn((overview.column + (e.key === Qt.Key_Backtab ? 2 : 1)) % 3); e.accepted = true }
                else if (e.key === Qt.Key_W && (e.modifiers & Qt.ControlModifier) && overview.column === 1 && windows.count) {
                    windows.requestClose(windows.makeModelIndex(winGrid.currentIndex)); e.accepted = true
                } else if (e.text.length === 1 && e.text >= " " && !(e.modifiers & Qt.ControlModifier) && !search.activeFocus) {
                    // just start typing: the search takes it from any column
                    toColumn(2); search.insert(search.cursorPosition, e.text); e.accepted = true
                }
            }

            // the home surface at 92 % (.x-ov): the windows behind show through slightly
            Rectangle { anchors.fill: parent; color: Qt.rgba(0, 0, 0, 0.92) }
            MouseArea { anchors.fill: parent; onClicked: overview.close() } // a click on empty space closes it

            // Events (.x-ov__events, 420 px): the phone's Events view, the same as the Events sidebar (EventsView.qml)
            Item {
                width: 420; height: parent.height
                Rectangle { anchors.right: parent.right; width: 1; height: parent.height; color: root.divider }
                EventsView {
                    id: feed
                    anchors { fill: parent; rightMargin: 1; topMargin: 8 }
                    onOpened: overview.close()
                    shown: overview.visible
                }
            }

            // Windows (.x-ov__wins): live pictures, two per row
            Item {
                x: 420; width: parent.width - 420 - 600; height: parent.height
                Text {
                    visible: windows.count === 0
                    anchors.centerIn: parent
                    text: "No open windows"; color: root.fgSecondary; font.pixelSize: 14
                }
                GridView {
                    id: winGrid
                    anchors { fill: parent; leftMargin: 40; rightMargin: 40; topMargin: 32 }
                    cellWidth: width / 2; cellHeight: Math.round(cellWidth * 0.66) + 40
                    clip: true
                    model: windows
                    keyNavigationEnabled: true
                    highlight: Item {}
                    Keys.onReturnPressed: { windows.requestActivate(windows.makeModelIndex(currentIndex)); overview.close() }
                    delegate: MouseArea {
                        id: card
                        required property var model
                        required property int index
                        width: winGrid.cellWidth; height: winGrid.cellHeight
                        hoverEnabled: true
                        onClicked: { windows.requestActivate(windows.makeModelIndex(index)); overview.close() }
                        readonly property bool picked: winGrid.activeFocus && GridView.isCurrentItem
                        Item {
                            id: shot
                            x: 16; width: parent.width - 32; height: parent.height - 40
                            Loader {
                                id: live
                                anchors.centerIn: parent
                                source: "Preview.qml"
                                onLoaded: {
                                    item.box = Qt.binding(() => Qt.size(shot.width, shot.height))
                                    item.winId = Qt.binding(() => card.model.WinIdList && card.model.WinIdList.length ? card.model.WinIdList[0] : "")
                                    item.windowSize = Qt.binding(() => card.model.Geometry ? Qt.size(card.model.Geometry.width, card.model.Geometry.height) : Qt.size(16, 10))
                                    item.icon = Qt.binding(() => card.model.decoration)
                                }
                            }
                            Rectangle {
                                anchors.centerIn: live; width: live.width + 10; height: live.height + 10; radius: 10
                                color: "transparent"; visible: card.picked; border { width: 2; color: root.accent }
                            }
                            // close (HdTaskCard on the desktop: the squircle appears on hover)
                            MouseArea {
                                visible: card.containsMouse || card.picked
                                x: live.x + live.width - 20; y: live.y - 10
                                width: 30; height: 30
                                onClicked: windows.requestClose(windows.makeModelIndex(card.index))
                                Squircle { anchors.fill: parent; size: 30; fill: "#E8553A"
                                    Kirigami.Icon { anchors.centerIn: parent; width: 16; height: 16; source: "window-close-symbolic"; color: "white"; isMask: true } }
                            }
                        }
                        Row {
                            anchors { horizontalCenter: parent.horizontalCenter; top: shot.bottom; topMargin: 10 }
                            spacing: 8
                            Kirigami.Icon { width: 20; height: 20; source: card.model.decoration; anchors.verticalCenter: parent.verticalCenter }
                            Text {
                                text: card.model.display || ""; color: "white"; font.pixelSize: 14
                                width: Math.min(implicitWidth, card.width - 60); elide: Text.ElideRight; anchors.verticalCenter: parent.verticalCenter
                            }
                        }
                    }
                }
            }

            // Apps (.x-ov__apps, 600 px)
            Item {
                x: parent.width - 600; width: 600; height: parent.height
                Rectangle { width: 1; height: parent.height; color: root.divider }
                QQC2.TextField {
                    id: search
                    x: 24; y: 24; width: parent.width - 48; height: 40
                    placeholderText: "Type to search apps, contacts, mail"
                    font.pixelSize: 16
                    text: root.query
                    onTextEdited: root.query = text
                    onActiveFocusChanged: if (activeFocus) overview.column = 2
                    Keys.onReturnPressed: if (root.matches.length) root.launch(root.matches[0])
                    Keys.onEnterPressed: if (root.matches.length) root.launch(root.matches[0])
                    Keys.onDownPressed: appGrid.forceActiveFocus()
                }
                Text {
                    id: hint
                    anchors { left: search.left; top: search.bottom; leftMargin: 4; topMargin: 8 }
                    text: root.query ? "Apps matching “" + root.query + "”" : "Just start typing"
                    color: root.fgSecondary; font.pixelSize: 13
                }
                GridView {
                    id: appGrid
                    anchors { left: parent.left; right: parent.right; top: hint.bottom; leftMargin: 24; rightMargin: 24; topMargin: 16 }
                    height: Math.min(parent.height - hint.y - hint.height - 40 - more.height, Math.ceil(count / 5) * cellHeight)
                    cellWidth: width / 5; cellHeight: 92
                    clip: true
                    model: root.matches
                    keyNavigationEnabled: true
                    highlight: Item {}
                    delegate: MouseArea {
                        id: app
                        required property var modelData
                        required property int index
                        width: appGrid.cellWidth; height: appGrid.cellHeight
                        hoverEnabled: true
                        onClicked: root.launch(modelData)
                        Keys.onReturnPressed: root.launch(modelData)
                        Squircle {
                            anchors { horizontalCenter: parent.horizontalCenter; top: parent.top }
                            size: 62; fill: root.pressed
                            visible: app.containsMouse || (appGrid.activeFocus && app.GridView.isCurrentItem)
                        }
                        AppTile {
                            anchors { horizontalCenter: parent.horizontalCenter; top: parent.top; topMargin: 4 }
                            source: app.modelData.icon
                            own: EtesianIcons.has(app.modelData.icon) || EtesianIcons.has(app.modelData.id)
                        }
                        Text {
                            anchors { left: parent.left; right: parent.right; top: parent.top; topMargin: 66; leftMargin: 2; rightMargin: 2 }
                            horizontalAlignment: Text.AlignHCenter
                            text: app.modelData.name; color: "white"; elide: Text.ElideRight
                            font.pixelSize: 12
                        }
                    }
                }
                // contacts, mail, files… (Search.qml; only this list goes if Plasma's search module is missing)
                Loader {
                    id: more
                    anchors { left: parent.left; right: parent.right; top: appGrid.bottom; leftMargin: 16; rightMargin: 16; topMargin: 8 }
                    height: item ? Math.min(item.implicitHeight, 360) : 0
                    clip: true
                    source: "Search.qml"
                    onLoaded: { item.width = Qt.binding(() => more.width); item.query = Qt.binding(() => root.query); item.ran.connect(overview.close) }
                }
            }

            // key hints, bottom right (XHints corner="br")
            Row {
                anchors { right: parent.right; bottom: parent.bottom; margins: 16 }
                spacing: 14
                Repeater {
                    model: [["Esc", "Close"], ["Tab", "Next column"], ["Enter", "Open"], ["Ctrl+W", "Close window"], ["Super+Space", "Search"]]
                    Row {
                        required property var modelData
                        spacing: 6
                        KeyCap { text: modelData[0] }
                        Text { text: modelData[1]; color: root.fgSecondary; font.pixelSize: 12; anchors.verticalCenter: parent.verticalCenter }
                    }
                }
            }
        }
    }

    /** a key as a small cap (XKey) */
    component KeyCap: Rectangle {
        property alias text: label.text
        width: label.implicitWidth + 12; height: 20; radius: 4; color: Qt.rgba(1, 1, 1, 0.14)
        anchors.verticalCenter: parent ? parent.verticalCenter : undefined
        Text { id: label; anchors.centerIn: parent; color: "white"; font { pixelSize: 11; bold: true } }
    }

    /** an app as a lit squircle in its icon's own colour with the icon on it (same as the dock) */
    component AppTile: Squircle {
        id: tile
        property var source
        /** the icon theme already draws this app as a lit squircle: show it whole, without the tile behind */
        property bool own: false
        size: 54
        fill: own ? "transparent" : colors.dominant.valid && colors.dominant.a > 0.5 ? Qt.darker(colors.dominant, 1.25) : "#3A3A3A"
        fillFrom: own ? "transparent" : colors.dominant.valid && colors.dominant.a > 0.5 ? Qt.lighter(colors.dominant, 1.15) : "#5A5A5A"
        Kirigami.ImageColors { id: colors; source: tile.source; Component.onCompleted: update(); onSourceChanged: update() }
        Kirigami.Icon { anchors.centerIn: parent; width: tile.own ? 54 : 34; height: width; source: tile.source; roundToIconSize: !tile.own }
    }
}
