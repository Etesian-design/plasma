/*
 * Etesian Events (etesian-design src/shell/desktop/XEventsPanel.vue, XMenuBar.vue .x-mbar__events).
 * In the menu bar: the count of new notifications in the accent bubble. Clicked, or Super+N: the phone's Events view
 * (EventsView.qml, also the Overview's left column) drops in under the bar on the right, 460 px wide. No toggles and no volume
 * here: they live in the status menu.
 */
import QtQuick
import QtQuick.Window
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.kirigami as Kirigami
import org.kde.notificationmanager as NotificationManager

PlasmoidItem {
    id: root

    readonly property color accent: "#4591FF"
    readonly property color fgSecondary: "#C8C8C8"
    readonly property color divider: Qt.rgba(1, 1, 1, 0.16)
    readonly property color pressed: Qt.rgba(1, 1, 1, 0.12)
    // only for the count in the bubble; the view keeps its own
    NotificationManager.Notifications { id: notes; showExpired: true; showDismissed: true; showJobs: false }
    readonly property int count: notes.count

    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground
    Plasmoid.icon: "preferences-desktop-notification-bell"
    toolTipMainText: "Events"
    toolTipSubText: count + " new · Super+N"
    preferredRepresentation: compactRepresentation

    // The count bubble (HdCountBubble: accent pill, white bold 12 px), with the pressed pill behind it on hover or while open.
    compactRepresentation: MouseArea {
        Layout.preferredWidth: bubble.width + 8
        hoverEnabled: true
        onClicked: root.expanded = !root.expanded
        Rectangle {
            anchors.centerIn: parent
            width: bubble.width + 8; height: 24; radius: 12
            color: root.pressed; visible: parent.containsMouse || root.expanded
        }
        Rectangle {
            id: bubble
            anchors.centerIn: parent
            width: Math.max(18, n.implicitWidth + 10); height: 18; radius: 9
            color: root.accent
            Text { id: n; anchors.centerIn: parent; text: root.count; color: "white"; font { pixelSize: 11; bold: true } }
        }
    }

    fullRepresentation: EventsView {
        Layout.preferredWidth: 460
        Layout.preferredHeight: Screen.height - 60
        Layout.minimumWidth: 460
        Keys.onEscapePressed: root.expanded = false
        onOpened: root.expanded = false
        shown: root.expanded
    }
}
