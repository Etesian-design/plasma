/*
 * The Etesian desktop status menu (etesian-design src/shell/desktop/XStatusPanel.vue, XMenuBar.vue .x-mbar__sicons).
 * In the menu bar: the Wi-Fi, Bluetooth and battery icons with the charge. A click drops the menu, separate from Events:
 * Wi-Fi, Bluetooth, Silent and Focus toggles, volume and brightness, then the battery and Settings.
 * Each part comes from a different Plasma module, some of them private; every part is loaded on its own, so a module that is
 * missing or has changed only takes its own row away (a desktop without Bluetooth simply has no Bluetooth toggle).
 */
import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.kirigami as Kirigami
import org.kde.plasma.plasma5support as P5Support
import org.kde.taskmanager as TaskManager

PlasmoidItem {
    id: root

    readonly property color fgSecondary: "#C8C8C8"
    readonly property color divider: Qt.rgba(1, 1, 1, 0.16)

    // Battery from the power-management engine (stable public API).
    P5Support.DataSource {
        id: power
        engine: "powermanagement"
        connectedSources: ["Battery", "AC Adapter"]
    }
    readonly property bool hasBattery: power.data["Battery"] ? power.data["Battery"]["Has Battery"] === true : false
    readonly property int percent: hasBattery ? power.data["Battery"]["Percent"] : 0
    readonly property bool plugged: power.data["AC Adapter"] ? power.data["AC Adapter"]["Plugged in"] === true : false
    readonly property real remaining: hasBattery ? (power.data["Battery"]["Remaining msec"] || 0) : 0
    function batteryIcon() {
        const level = Math.min(100, Math.round(percent / 10) * 10)
        return "battery-" + String(level).padStart(3, "0") + (plugged ? "-charging" : "") + "-symbolic"
    }

    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground
    Plasmoid.icon: "network-wireless-symbolic"
    preferredRepresentation: compactRepresentation
    toolTipMainText: "Status"
    toolTipSubText: hasBattery ? percent + "%" : ""

    compactRepresentation: MouseArea {
        Layout.preferredWidth: icons.implicitWidth + 16
        hoverEnabled: true
        onClicked: root.expanded = !root.expanded
        Rectangle {
            anchors.centerIn: parent; width: parent.width; height: 24; radius: 12
            color: Qt.rgba(1, 1, 1, 0.12); visible: parent.containsMouse || root.expanded
        }
        Row {
            id: icons
            anchors.centerIn: parent
            spacing: 10
            Kirigami.Icon { width: 15; height: 15; source: "network-wireless-symbolic"; color: "white"; isMask: true; anchors.verticalCenter: parent.verticalCenter }
            Kirigami.Icon { width: 15; height: 15; source: "network-bluetooth-symbolic"; color: "white"; isMask: true; anchors.verticalCenter: parent.verticalCenter }
            Row {
                visible: root.hasBattery
                spacing: 3
                anchors.verticalCenter: parent.verticalCenter
                Kirigami.Icon { width: 17; height: 17; source: root.batteryIcon(); color: "white"; isMask: true }
                Text { text: root.percent + "%"; color: "white"; font.pixelSize: 12; anchors.verticalCenter: parent.verticalCenter }
            }
        }
    }

    fullRepresentation: Item {
        Layout.preferredWidth: 360
        Layout.preferredHeight: col.implicitHeight + 28
        Layout.minimumWidth: 360
        Layout.minimumHeight: Layout.preferredHeight

        Column {
            id: col
            x: 14; y: 14; width: 332
            spacing: 10

            Grid {
                columns: 2; spacing: 8
                Part { source: "WifiToggle.qml" }
                Part { source: "BluetoothToggle.qml" }
                Part { source: "SilentToggle.qml" }
                Part { source: "FocusToggle.qml" }
            }
            Part { source: "VolumeRow.qml" }
            Part { source: "BrightnessRow.qml" }
            Rectangle { width: parent.width; height: 1; color: root.divider }
            Item {
                width: parent.width; height: 34
                Row {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 6
                    visible: root.hasBattery
                    Kirigami.Icon { width: 18; height: 18; source: root.batteryIcon(); color: root.fgSecondary; isMask: true }
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        color: root.fgSecondary; font.pixelSize: 12
                        text: {
                            const m = Math.round(root.remaining / 60000)
                            return root.percent + "%" + (root.plugged ? " · charging" : m > 0 ? " · " + Math.floor(m / 60) + " h " + (m % 60) + " min left" : "")
                        }
                    }
                }
                // Settings: the pill button with the gear (HdButton icon="settings").
                MouseArea {
                    id: settingsButton
                    anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                    width: settingsRow.implicitWidth + 28; height: 34
                    hoverEnabled: true
                    onClicked: { root.expanded = false; root.start("systemsettings.desktop") }
                    Rectangle { anchors.fill: parent; radius: 17; color: settingsButton.containsMouse ? Qt.rgba(1, 1, 1, 0.2) : Qt.rgba(1, 1, 1, 0.12) }
                    Row {
                        id: settingsRow
                        anchors.centerIn: parent; spacing: 6
                        Kirigami.Icon { width: 16; height: 16; source: "configure-symbolic"; color: "white"; isMask: true; anchors.verticalCenter: parent.verticalCenter }
                        Text { text: "Settings"; color: "white"; font.pixelSize: 13; anchors.verticalCenter: parent.verticalCenter }
                    }
                }
            }
        }
    }

    /** one part of the menu: hidden when its module is not there */
    component Part: Loader {
        // a part says whether it has anything to show (its module may be there while the hardware or service is not)
        visible: status === Loader.Ready && item && item.available !== false
    }

    // Apps start through a task model so they come up focused (same as the dock and the launcher).
    TaskManager.TasksModel { id: starter; filterByVirtualDesktop: false; filterByActivity: false }
    function start(desktopFile) {
        starter.launcherList = ["applications:" + desktopFile]
        for (let i = 0; i < starter.count; i++) {
            const idx = starter.makeModelIndex(i)
            if (starter.data(idx, TaskManager.AbstractTasksModel.IsLauncher)) { starter.requestNewInstance(idx); break }
        }
    }
}
