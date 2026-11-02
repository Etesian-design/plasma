// Everything else the query matches: people, mail, files and folders, settings… from Plasma's search runners (KRunner, the
// same results as Kickoff), grouped by kind under the app grid. Apps are left out: the grid already shows them.
import QtQuick
import org.kde.milou as Milou
import org.kde.kirigami as Kirigami

Column {
    id: search
    property string query
    /** the number of rows shown */
    readonly property int shown: rows.count
    signal ran()
    width: 760
    spacing: 0

    Milou.ResultsModel { id: results; queryString: search.query; limit: 24 }

    Repeater {
        id: rows
        model: search.query.trim().length >= 2 ? results : []
        delegate: MouseArea {
            id: row
            required property var model
            required property int index
            readonly property string kind: model.category || ""
            readonly property bool isApp: kind === "Applications"
            readonly property bool first: index === 0 || results.data(results.index(index - 1, 0), Milou.ResultsModel.CategoryRole) !== kind
            visible: !isApp
            width: search.width; height: visible ? (first ? 30 : 0) + 44 : 0
            hoverEnabled: true
            onClicked: if (results.run(results.index(index, 0))) search.ran()
            // the kind, as a section header (HdSectionHeader)
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
                    Kirigami.Icon { anchors.centerIn: parent; width: 22; height: 22; source: row.model.decoration } }
                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    Text { text: row.model.display || ""; color: "white"; font.pixelSize: 14; elide: Text.ElideRight; width: search.width - 80 }
                    Text { visible: text !== ""; text: String(row.model.subtext || ""); color: "#C8C8C8"; font.pixelSize: 12; elide: Text.ElideMiddle; width: search.width - 80 }
                }
            }
        }
    }
}
