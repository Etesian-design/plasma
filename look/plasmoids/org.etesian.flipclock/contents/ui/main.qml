/*
 * Belle's flip clock on the desktop (etesian-design belle/BelleWidget.vue .bw-flip; the phone's bc_flipclock): hours and minutes
 * on two dark tiles with a hinge line and side pins, the date under the minutes. 4 × 2 cells (360 × 180 px).
 */
import QtQuick
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore

PlasmoidItem {
    id: root
    property date now: new Date()
    Timer { interval: 1000; running: true; repeat: true; onTriggered: root.now = new Date() }
    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground
    preferredRepresentation: fullRepresentation
    implicitWidth: 360; implicitHeight: 180

    fullRepresentation: Row {
        padding: 2; spacing: 6
        Repeater {
            model: [Qt.formatTime(root.now, "hh"), Qt.formatTime(root.now, "mm")]
            delegate: Rectangle {
                width: 174; height: 176; radius: 16; border { color: "black"; width: 1.5 }
                gradient: Gradient { GradientStop { position: 0; color: "#2C2D31" } GradientStop { position: 0.5; color: "#111214" } GradientStop { position: 1; color: "black" } }
                Rectangle { anchors { fill: parent; margins: 1.5 } radius: 15; opacity: 0.12
                    gradient: Gradient { GradientStop { position: 0; color: "white" } GradientStop { position: 0.4; color: "transparent" } } }
                Text { anchors.centerIn: parent; text: modelData; color: "white"; font { pixelSize: 84; bold: true } style: Text.Raised; styleColor: "#AA000000" }
                Rectangle { anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter } height: 1; color: "#6A6B70" }
                Repeater { model: 2; Rectangle { x: index ? parent.width - 4 : 0; anchors.verticalCenter: parent.verticalCenter; width: 4; height: 18; radius: 2; color: "#4A4B50" } }
                Text { visible: index === 1; anchors { bottom: parent.bottom; bottomMargin: 10; horizontalCenter: parent.horizontalCenter }
                    text: Qt.formatDate(root.now, "ddd MMM d"); color: "#9A9BA0"; font.pixelSize: 15 }
            }
        }
    }
}
