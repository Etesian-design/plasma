/*
 * Search (Super+Space): a compact panel centred near the top of the screen, over the windows: a search field, the
 * app grid (6 columns of 64 px squircles) and, while typing, people, mail, files and more from Plasma's search runners.
 * Enter opens the first match, Esc or Super+Space again closes it. It is an addition to the Overview (Super, the main menu;
 * org.etesian.launcher), not a replacement. The widget has nothing to show in the bar: only the shortcut opens it.
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
    readonly property color pressed: Qt.rgba(1, 1, 1, 0.12)
    readonly property int cell: 52

    preferredRepresentation: fullRepresentation
    activationTogglesExpanded: false
    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground
    Plasmoid.icon: "view-app-grid-symbolic"
    Layout.preferredWidth: 0; Layout.preferredHeight: 0
    Layout.maximumWidth: 0; Layout.maximumHeight: 0

    Connections {
        target: Plasmoid
        function onActivated() { panel.visible ? panel.close() : panel.open() }
    }

    // Every installed app, read by contents/code/apps.sh ("id<TAB>name<TAB>icon" per line) each time the panel opens.
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
    /** the apps whose name matches the query */
    readonly property var matches: {
        const q = query.trim().toLowerCase()
        return q ? allApps.filter(a => a.name.toLowerCase().indexOf(q) >= 0) : allApps
    }
    // Started the way the dock starts its launchers: through a task model, which hands the app an activation token so it
    // comes up focused. (Plasma's own app model, org.kde.plasma.private.kicker, crashes Plasma 6.8 in a third-party widget.)
    TaskManager.TasksModel { id: starter; filterByVirtualDesktop: false; filterByActivity: false }
    function launch(app) {
        panel.close()
        if (!/^[\w.+-]+\.desktop$/.test(app.id)) return
        starter.launcherList = ["applications:" + app.id]
        for (let i = 0; i < starter.count; i++) {
            const idx = starter.makeModelIndex(i)
            if (starter.data(idx, TaskManager.AbstractTasksModel.IsLauncher)) { starter.requestNewInstance(idx); break }
        }
    }

    fullRepresentation: Item {} // nothing in the bar

    // The panel: 760 px wide, 90 px from the top, centred on the screen (XLauncher .x-launch).
    PlasmaCore.Dialog {
        id: panel
        location: PlasmaCore.Types.Floating
        hideOnWindowDeactivate: true
        flags: Qt.WindowStaysOnTopHint
        visible: false
        function open() {
            root.query = ""
            root.refresh()
            const s = Plasmoid.containment.screenGeometry
            x = s.x + (s.width - mainItem.width - margins.left - margins.right) / 2
            y = s.y + 90
            visible = true
            search.forceActiveFocus()
        }
        function close() { visible = false }

        mainItem: FocusScope {
            width: 760
            height: 120 + grid.height + more.height
            Keys.onEscapePressed: panel.close()

            QQC2.TextField {
                id: search
                anchors { left: parent.left; right: parent.right; top: parent.top; margins: 4 }
                height: 40
                placeholderText: "Type to search apps, people, mail and files"
                text: root.query
                onTextEdited: root.query = text
                font.pixelSize: 16
                focus: true
                Keys.onReturnPressed: if (root.matches.length) root.launch(root.matches[0])
                Keys.onEnterPressed: if (root.matches.length) root.launch(root.matches[0])
                Keys.onDownPressed: grid.forceActiveFocus()
            }
            Row {
                id: sub
                anchors { left: parent.left; top: search.bottom; leftMargin: 8; topMargin: 12 }
                spacing: 6
                Text {
                    text: root.query ? "Apps matching “" + root.query + "” ·" : "All applications ·"
                    color: root.fgSecondary; font.pixelSize: 13; anchors.verticalCenter: parent.verticalCenter
                }
                KeyCap { text: root.query ? "Enter" : "Super" }
                Text {
                    text: root.query ? "opens the first" : "opens the Overview"
                    color: root.fgSecondary; font.pixelSize: 13; anchors.verticalCenter: parent.verticalCenter
                }
            }
            GridView {
                id: grid
                anchors { left: parent.left; right: parent.right; top: sub.bottom; topMargin: 16 }
                height: Math.min(4, Math.ceil(count / 6)) * cellHeight
                cellWidth: width / 6; cellHeight: 104
                clip: true
                model: root.matches
                keyNavigationEnabled: true
                highlight: Item {}
                delegate: MouseArea {
                    id: app
                    required property var modelData
                    required property int index
                    width: grid.cellWidth; height: grid.cellHeight
                    hoverEnabled: true
                    onClicked: root.launch(modelData)
                    Keys.onReturnPressed: root.launch(modelData)
                    Squircle {
                        anchors { horizontalCenter: parent.horizontalCenter; top: parent.top; topMargin: 2 }
                        size: 72; fill: root.pressed
                        visible: app.containsMouse || (grid.activeFocus && app.GridView.isCurrentItem)
                    }
                    AppTile { anchors { horizontalCenter: parent.horizontalCenter; top: parent.top; topMargin: 6 } source: app.modelData.icon; own: EtesianIcons.has(app.modelData.icon) || EtesianIcons.has(app.modelData.id) }
                    Text {
                        anchors { left: parent.left; right: parent.right; top: parent.top; topMargin: 78; leftMargin: 4; rightMargin: 4 }
                        horizontalAlignment: Text.AlignHCenter
                        text: app.modelData.name; color: "white"; elide: Text.ElideRight
                        font.pixelSize: 13
                    }
                }
            }
            // people, mail, files… (Search.qml; only its own list goes if Plasma's search module is missing)
            Loader {
                id: more
                anchors { left: parent.left; right: parent.right; top: grid.bottom }
                height: item ? Math.min(item.implicitHeight, 300) : 0
                clip: true
                source: "Search.qml"
                onLoaded: { item.query = Qt.binding(() => root.query); item.ran.connect(panel.close) }
            }
        }
    }

    /** a key as a small cap (XKey) */
    component KeyCap: Rectangle {
        property alias text: label.text
        width: label.implicitWidth + 12; height: 20; radius: 4; color: Qt.rgba(1, 1, 1, 0.14)
        anchors.verticalCenter: parent.verticalCenter
        Text { id: label; anchors.centerIn: parent; color: "white"; font { pixelSize: 11; bold: true } }
    }

    /** an app as a lit squircle in its icon's own colour with the icon on it (same as the dock) */
    component AppTile: Squircle {
        id: tile
        property var source
        /** the icon theme already draws this app as a lit squircle: show it whole, without the tile behind */
        property bool own: false
        size: 64
        fill: own ? "transparent" : colors.dominant.valid && colors.dominant.a > 0.5 ? Qt.darker(colors.dominant, 1.25) : "#3A3A3A"
        fillFrom: own ? "transparent" : colors.dominant.valid && colors.dominant.a > 0.5 ? Qt.lighter(colors.dominant, 1.15) : "#5A5A5A"
        Kirigami.ImageColors { id: colors; source: tile.source; Component.onCompleted: update(); onSourceChanged: update() }
        Kirigami.Icon { anchors.centerIn: parent; width: tile.own ? 64 : 42; height: width; source: tile.source }
    }
}
