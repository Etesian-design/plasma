// A key cap in a hint (etesian-design parts/XKey.vue): the key name on a faint outlined plate.
import QtQuick

Rectangle {
    property alias text: label.text
    implicitWidth: label.implicitWidth + 12
    implicitHeight: 20
    radius: 4
    color: Qt.rgba(1, 1, 1, 0.08)
    border { width: 1; color: Qt.rgba(1, 1, 1, 0.28) }
    Text { id: label; anchors.centerIn: parent; color: "white"; font { pixelSize: 11; bold: true } }
}
