/*
 * Belle's RSS widget on the desktop (belle/BelleWidget.vue .bw-rss; the phone's BelleRssWidget): an orange header with the
 * feed's name, when it was updated and a refresh button, over a white list of the newest posts, newest first, scrolling.
 * The feeds are the ones in Events (SharedSettings.qml, ~/.config/etesianrc); a post opens in the browser. 4 × 3 cells.
 */
import QtQuick
import QtQuick.Controls as QQC2
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.kirigami as Kirigami

PlasmoidItem {
    id: root
    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground
    preferredRepresentation: fullRepresentation
    implicitWidth: 360; implicitHeight: 270
    SharedSettings { id: settings }
    Feeds { id: feeds; urls: settings.feeds }
    property date updated: new Date()
    Connections { target: feeds; function onItemsChanged() { root.updated = new Date() } }

    fullRepresentation: Item {
        implicitWidth: 360; implicitHeight: 270
        Rectangle {
            id: head
            anchors { left: parent.left; right: parent.right; top: parent.top }
            height: 52; topLeftRadius: 10; topRightRadius: 10
            gradient: Gradient { GradientStop { position: 0; color: "#F7A13A" } GradientStop { position: 1; color: "#E5620F" } }
            Column {
                anchors { left: parent.left; leftMargin: 14; verticalCenter: parent.verticalCenter; right: refresh.left }
                Text { width: parent.width; elide: Text.ElideRight; color: "white"; font { pixelSize: 18; bold: true } style: Text.Raised; styleColor: "#66000000"
                    text: feeds.list.length === 1 && feeds.items.length ? feeds.items[0].source : "Feeds" }
                Text { color: "white"; opacity: 0.9; font.pixelSize: 13; text: "Updated " + Qt.formatTime(root.updated, "hh:mm") }
            }
            MouseArea {
                id: refresh
                anchors { right: parent.right; rightMargin: 12; verticalCenter: parent.verticalCenter }
                width: 30; height: 30
                onClicked: feeds.refresh()
                Kirigami.Icon { anchors.fill: parent; source: "view-refresh"; color: "white"; isMask: true }
            }
        }
        Rectangle {
            anchors { left: parent.left; right: parent.right; top: head.bottom; bottom: parent.bottom }
            bottomLeftRadius: 10; bottomRightRadius: 10; clip: true
            gradient: Gradient { GradientStop { position: 0; color: "white" } GradientStop { position: 1; color: "#E9E9EB" } }
            Text {
                visible: !feeds.items.length; anchors { fill: parent; margins: 14 }
                wrapMode: Text.Wrap; verticalAlignment: Text.AlignVCenter; horizontalAlignment: Text.AlignHCenter
                color: "#6A6A6A"; font.pixelSize: 15
                text: feeds.list.length ? "Loading…" : "No feeds yet. Add one under Feeds in Events (Super+N)."
            }
            ListView {
                id: posts
                anchors { fill: parent; leftMargin: 14; rightMargin: 14; bottomMargin: 4 }
                model: feeds.items
                boundsBehavior: Flickable.StopAtBounds
                QQC2.ScrollBar.vertical: QQC2.ScrollBar { }
                delegate: MouseArea {
                    width: posts.width; height: Math.max(52, title.implicitHeight + 16)
                    onClicked: Qt.openUrlExternally(modelData.link)
                    Rectangle { visible: index > 0; anchors { left: parent.left; right: parent.right; top: parent.top } height: 1; color: "#DADADD" }
                    Row {
                        anchors.verticalCenter: parent.verticalCenter; spacing: 12
                        Rectangle { width: 9; height: 9; radius: 4.5; anchors.verticalCenter: parent.verticalCenter
                            gradient: Gradient { GradientStop { position: 0; color: "#4DB2F0" } GradientStop { position: 1; color: "#1C8FD8" } } }
                        Text { id: title; width: posts.width - 21; text: modelData.title; color: "#1A1A1A"; font.pixelSize: 15
                            wrapMode: Text.Wrap; maximumLineCount: 3; elide: Text.ElideRight }
                    }
                }
            }
        }
    }
}
