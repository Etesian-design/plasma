/*
 * Belle's Mail widget on the desktop (belle/BelleWidget.vue .bw-mail; Belle Mail widget 4.5): the account and the unread count in
 * a blue header, over a white list of the newest mails (up to 20, scrolling), unread ones with a blue dot. A mail opens in
 * KMail; the header opens KMail. Mails come from KMail's inboxes (MailSource.qml, the Etesian mail plugin). 4 × 3 cells.
 */
import QtQuick
import QtQuick.Controls as QQC2
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore

PlasmoidItem {
    id: root
    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground
    preferredRepresentation: fullRepresentation
    implicitWidth: 360; implicitHeight: 270
    MailSource { id: src; source: Plasmoid.configuration.source; account: Plasmoid.configuration.account }
    readonly property var inbox: src.inbox
    // One debug line when what it shows changes (the tests read it; Plasma hides debug output unless asked for).
    readonly property string summary: inbox ? inbox.count + " mails, " + inbox.unread + " unread, first " + (inbox.count ? inbox.firstFrom : "-") + ", account " + inbox.accountName : ""
    onSummaryChanged: if (summary) console.debug("Mail widget: " + summary)

    function when(d) {
        const now = new Date()
        if (d.toDateString() === now.toDateString()) return Qt.formatTime(d, "hh:mm")
        return Qt.formatDate(d, d.getFullYear() === now.getFullYear() ? "d MMM" : "d MMM yyyy")
    }

    fullRepresentation: Item {
        implicitWidth: 360; implicitHeight: 270
        Rectangle {
            id: head
            anchors { left: parent.left; right: parent.right; top: parent.top }
            height: 40; topLeftRadius: 10; topRightRadius: 10
            gradient: Gradient { GradientStop { position: 0; color: "#4DB2F0" } GradientStop { position: 1; color: "#0E6CB8" } }
            MouseArea { anchors.fill: parent; onClicked: if (root.inbox) root.inbox.open(-1) }
            Text {
                anchors { left: parent.left; right: parent.right; leftMargin: 44; rightMargin: 44; verticalCenter: parent.verticalCenter }
                horizontalAlignment: Text.AlignHCenter; elide: Text.ElideRight
                color: "white"; font.pixelSize: 18; style: Text.Raised; styleColor: "#80000000"
                text: root.inbox && root.inbox.accountName ? root.inbox.accountName : "Mail"
            }
            Rectangle {
                visible: !!root.inbox && root.inbox.unread > 0
                anchors { right: parent.right; rightMargin: 6; verticalCenter: parent.verticalCenter }
                width: 32; height: 32; radius: 16
                gradient: Gradient { GradientStop { position: 0; color: "white" } GradientStop { position: 1; color: "#D6E6F2" } }
                Text { anchors.centerIn: parent; color: "#0E5E9E"; font.pixelSize: 15; text: root.inbox ? Math.min(root.inbox.unread, 999) : "" }
            }
        }
        Rectangle {
            anchors { left: parent.left; right: parent.right; top: head.bottom; bottom: parent.bottom }
            bottomLeftRadius: 10; bottomRightRadius: 10; clip: true
            gradient: Gradient { GradientStop { position: 0; color: "white" } GradientStop { position: 1; color: "#E9E9EB" } }
            Text {
                visible: !mails.count; anchors { fill: parent; margins: 14 }
                wrapMode: Text.Wrap; verticalAlignment: Text.AlignVCenter; horizontalAlignment: Text.AlignHCenter
                color: "#6A6A6A"; font.pixelSize: 15
                text: src.missing || (!root.inbox.available ? "No mail account yet. Add one in KMail." : "No mails in the inbox.")
            }
            ListView {
                id: mails
                anchors { fill: parent; leftMargin: 10; rightMargin: 16; bottomMargin: 4 }
                model: root.inbox
                boundsBehavior: Flickable.StopAtBounds
                // thin and always shown while there is more (.bw-scroll), in the margin beside the times
                QQC2.ScrollBar.vertical: QQC2.ScrollBar {
                    parent: mails.parent
                    anchors { top: mails.top; bottom: mails.bottom; left: mails.right; leftMargin: 6; topMargin: 6 }
                    policy: mails.contentHeight > mails.height ? QQC2.ScrollBar.AlwaysOn : QQC2.ScrollBar.AlwaysOff
                    padding: 0; background: null
                    contentItem: Rectangle { implicitWidth: 4; radius: 2; color: "#A6A6AB" }
                }
                delegate: MouseArea {
                    required property int index
                    required property string from
                    required property string subject
                    required property date date
                    required property bool unread
                    width: mails.width; height: 58
                    onClicked: root.inbox.open(index)
                    Rectangle { visible: index > 0; anchors { left: parent.left; right: parent.right; top: parent.top } height: 1; color: "#DADADD" }
                    Rectangle {
                        id: dot
                        visible: unread
                        anchors { left: parent.left; verticalCenter: parent.verticalCenter }
                        width: 9; height: 9; radius: 4.5
                        gradient: Gradient { GradientStop { position: 0; color: "#4DB2F0" } GradientStop { position: 1; color: "#1C8FD8" } }
                    }
                    Column {
                        anchors { left: parent.left; leftMargin: 18; right: time.left; rightMargin: 8; verticalCenter: parent.verticalCenter }
                        Text { width: parent.width; elide: Text.ElideRight; color: "#1A1A1A"; font { pixelSize: 16; bold: true } text: from || "(no sender)" }
                        Text { width: parent.width; elide: Text.ElideRight; color: "#6E6E73"; font.pixelSize: 14; text: subject || "(no subject)" }
                    }
                    Text { id: time; anchors { right: parent.right; top: parent.top; topMargin: 9 } color: "#1C8FD8"; font.pixelSize: 14; text: root.when(date) }
                }
            }
        }
    }
}
