// Everything else the query matches, grouped by kind under the app grid:
//   people and mail from Thunderbird (its address books and inboxes; the Etesian mail plugin, look/mail), so they show
//   without KDE PIM; left out when the plugin is missing
//   files and folders, settings… and, with KDE PIM, its people and mail: Plasma's search runners (KRunner, as Kickoff)
// Apps are left out: the grid already shows them.
import QtQuick
import org.kde.milou as Milou
import org.kde.kirigami as Kirigami

Column {
    id: search
    property string query
    /** the number of rows shown */
    readonly property int shown: own.count + runners.count
    signal ran()
    width: 760
    spacing: 0

    readonly property bool typed: search.query.trim().length >= 2
    readonly property var thunderbird: { try { return Qt.createQmlObject('import org.etesian.mail; ThunderbirdSearch { }', search, "Search.qml") } catch (e) { return null } }
    Binding { target: search.thunderbird; property: "query"; value: search.query; when: !!search.thunderbird }
    Milou.ResultsModel { id: results; queryString: search.query; limit: 24 }

    Repeater {
        id: own
        model: search.typed && search.thunderbird ? search.thunderbird : []
        delegate: ResultRow {
            required property var model
            required property int index
            kind: model.kind; display: model.display; subtext: model.subtext; icon: model.icon
            first: index === 0 || search.thunderbird.data(search.thunderbird.index(index - 1, 0), Qt.UserRole + 1) !== kind
            onClicked: { search.thunderbird.run(index); search.ran() }
        }
    }

    Repeater {
        id: runners
        model: search.typed ? results : []
        delegate: ResultRow {
            required property var model
            required property int index
            kind: model.category || ""
            display: model.display || ""; subtext: String(model.subtext || ""); icon: model.decoration
            visible: kind !== "Applications"
            first: index === 0 || results.data(results.index(index - 1, 0), Milou.ResultsModel.CategoryRole) !== kind
            onClicked: if (results.run(results.index(index, 0))) search.ran()
        }
    }

    /** one result: its kind as a section header above the first of each kind (HdSectionHeader), then icon, title and detail */
    component ResultRow: MouseArea {
        id: row
        property string kind
        property string display
        property string subtext
        property var icon
        property bool first
        width: search.width; height: visible ? (first ? 30 : 0) + 44 : 0
        hoverEnabled: true
        Row {
            visible: row.first
            x: 8; y: 10; spacing: 8
            Text { id: h; text: row.kind; color: "#C8C8C8"; font { pixelSize: 12; bold: true } }
            Rectangle { anchors.verticalCenter: h.verticalCenter; width: search.width - h.width - 24; height: 1; color: Qt.rgba(1, 1, 1, 0.16) }
        }
        Rectangle { y: row.first ? 30 : 0; width: parent.width; height: 44; radius: 8; color: Qt.rgba(1, 1, 1, 0.12); visible: row.containsMouse }
        Row {
            x: 10; y: (row.first ? 30 : 0) + 6; spacing: 12
            Squircle { size: 32; fill: Qt.rgba(1, 1, 1, 0.10)
                Kirigami.Icon { anchors.centerIn: parent; width: 22; height: 22; source: row.icon } }
            Column {
                anchors.verticalCenter: parent.verticalCenter
                Text { text: row.display; color: "white"; font.pixelSize: 14; elide: Text.ElideRight; width: search.width - 80 }
                Text { visible: text !== ""; text: row.subtext; color: "#C8C8C8"; font.pixelSize: 12; elide: Text.ElideMiddle; width: search.width - 80 }
            }
        }
    }
}
