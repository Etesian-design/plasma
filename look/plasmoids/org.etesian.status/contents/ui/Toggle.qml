// A status-menu toggle (XStatusPanel .x-stat__tg): a squircle icon, lit in the accent when on, the label and its state.
import QtQuick
import org.kde.kirigami as Kirigami

MouseArea {
    id: tg
    property string label
    property string sub
    property string icon
    property bool on: false
    width: 160; height: 52
    hoverEnabled: true
    Rectangle { anchors.fill: parent; radius: 8; color: tg.containsMouse ? Qt.rgba(1, 1, 1, 0.12) : Qt.rgba(1, 1, 1, 0.07) }
    Squircle {
        x: 10; anchors.verticalCenter: parent.verticalCenter; size: 34
        fill: tg.on ? "#4591FF" : Qt.rgba(1, 1, 1, 0.14)
        fillFrom: tg.on ? Qt.lighter("#4591FF", 1.3) : fill
        Kirigami.Icon { anchors.centerIn: parent; width: 18; height: 18; source: tg.icon; color: "white"; isMask: true }
    }
    Column {
        x: 54; anchors.verticalCenter: parent.verticalCenter; spacing: 3
        Text { text: tg.label; color: "white"; font { pixelSize: 13; bold: true } }
        Text { text: tg.on ? tg.sub : "Off"; color: "#C8C8C8"; font.pixelSize: 12; width: tg.width - 62; elide: Text.ElideRight }
    }
}
