// "Edit dock" settings popover (XDockSettings.vue): Style, Position, Size, Visibility, Widgets, then Add widgets… and Done.
import QtQuick
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami

Item {
    id: set
    property string style: "strip"         // strip | panel
    property string position: "left"
    property int size: 44
    property string visibility: "always"   // always | autohide | dodge
    property var widgets: []                // [{ id, label, icon, on }]
    signal styleSet(string v)
    signal positionSet(string v)
    signal sizeSet(int v)
    signal visibilitySet(string v)
    signal widgetSet(string id, bool on)
    signal addWidgets()
    signal done()
    readonly property color accent: "#4591FF"
    readonly property color divider: Qt.rgba(1, 1, 1, 0.16)
    width: 380; height: col.implicitHeight + 32

    Column {
        id: col
        x: 20; y: 18; width: 340
        Text { text: "Dock"; color: "white"; font { pixelSize: 28; weight: Font.Light } bottomPadding: 6 }
        SubHeader { text: "Style" }
        Segments { options: [["strip", "Floating strip"], ["panel", "Full-height panel"]]; current: set.style; onPicked: (v) => set.styleSet(v) }
        SubHeader { text: "Position" }
        Row {
            spacing: 8
            Repeater {
                model: ["left", "bottom", "right", "top"]
                MouseArea {
                    id: pos
                    required property string modelData
                    readonly property bool on: set.position === modelData
                    width: (340 - 24) / 4; height: 62
                    onClicked: set.positionSet(modelData)
                    Rectangle { anchors.fill: parent; radius: 6; color: pos.on ? Qt.rgba(69 / 255, 145 / 255, 1, 0.18) : "transparent"; border { width: 1; color: pos.on ? set.accent : set.divider } }
                    Rectangle {
                        id: mini
                        x: (parent.width - 52) / 2; y: 8; width: 52; height: 32; radius: 3; color: Qt.rgba(1, 1, 1, 0.14)
                        Rectangle {
                            radius: 2; color: pos.on ? set.accent : "#C8C8C8"
                            readonly property bool side: pos.modelData === "left" || pos.modelData === "right"
                            width: side ? 6 : parent.width - 8; height: side ? parent.height - 8 : 6
                            x: pos.modelData === "left" ? 3 : pos.modelData === "right" ? parent.width - 9 : 4
                            y: pos.modelData === "top" ? 3 : pos.modelData === "bottom" ? parent.height - 9 : 4
                        }
                    }
                    Text { anchors { horizontalCenter: parent.horizontalCenter; top: mini.bottom; topMargin: 6 } text: pos.modelData[0].toUpperCase() + pos.modelData.slice(1); color: "white"; font.pixelSize: 11 }
                }
            }
        }
        SubHeader { text: "Size · " + slider.value + " px icons" }
        QQC2.Slider { id: slider; width: 340; from: 32; to: 72; stepSize: 4; snapMode: QQC2.Slider.SnapAlways; value: set.size; onMoved: set.sizeSet(value) }
        SubHeader { text: "Visibility" }
        Segments { options: [["always", "Always visible"], ["autohide", "Auto-hide"], ["dodge", "Dodge windows"]]; current: set.visibility; onPicked: (v) => set.visibilitySet(v) }
        SubHeader { text: "Widgets" }
        Repeater {
            model: set.widgets
            Item {
                required property var modelData
                width: 340; height: 40
                Squircle { anchors.verticalCenter: parent.verticalCenter; size: 28; fill: Qt.rgba(1, 1, 1, 0.12)
                    Kirigami.Icon { anchors.centerIn: parent; width: 16; height: 16; source: modelData.icon; color: "white"; isMask: true } }
                Text { x: 38; anchors.verticalCenter: parent.verticalCenter; text: modelData.label; color: "white"; font.pixelSize: 13 }
                QQC2.Switch { anchors { right: parent.right; verticalCenter: parent.verticalCenter } checked: modelData.on; onToggled: set.widgetSet(modelData.id, checked) }
            }
        }
        Rectangle { width: 340; height: 1; color: set.divider }
        Item {
            width: 340; height: 50
            Pill { anchors { left: parent.left; verticalCenter: parent.verticalCenter } icon: "list-add-symbolic"; text: "Add widgets…"; onClicked: set.addWidgets() }
            Pill { anchors { right: parent.right; verticalCenter: parent.verticalCenter } text: "Done"; accent: true; onClicked: set.done() }
        }
    }

    component SubHeader: Text { color: "#C8C8C8"; font { pixelSize: 11; bold: true; capitalization: Font.AllUppercase; letterSpacing: 0.5 } topPadding: 14; bottomPadding: 8 }
    component Segments: Rectangle {
        id: seg
        property var options: []
        property string current
        signal picked(string v)
        width: 340; height: 34; radius: 6; color: "transparent"; clip: true; border { width: 1; color: set.divider }
        Row {
            Repeater {
                model: seg.options
                MouseArea {
                    required property var modelData
                    required property int index
                    readonly property bool on: seg.current === modelData[0]
                    width: 340 / seg.options.length; height: 34
                    onClicked: seg.picked(modelData[0])
                    Rectangle { anchors.fill: parent; anchors.margins: 1; radius: 5; visible: parent.on
                        gradient: Gradient { GradientStop { position: 0; color: Qt.lighter(set.accent, 1.25) } GradientStop { position: 1; color: set.accent } } }
                    Rectangle { visible: index > 0; width: 1; height: parent.height; color: set.divider }
                    Text { anchors.centerIn: parent; text: modelData[1]; color: "white"; font { pixelSize: 11; bold: parent.on } }
                }
            }
        }
    }
    component Pill: MouseArea {
        id: pill
        property string text; property string icon; property bool accent: false
        width: r.implicitWidth + 28; height: 34; hoverEnabled: true
        Rectangle { anchors.fill: parent; radius: 17; color: pill.accent ? set.accent : pill.containsMouse ? Qt.rgba(1, 1, 1, 0.2) : Qt.rgba(1, 1, 1, 0.12) }
        Row { id: r; anchors.centerIn: parent; spacing: 6
            Kirigami.Icon { visible: pill.icon !== ""; width: 16; height: 16; source: pill.icon; color: "white"; isMask: true; anchors.verticalCenter: parent.verticalCenter }
            Text { text: pill.text; color: "white"; font { pixelSize: 13; bold: pill.accent } anchors.verticalCenter: parent.verticalCenter } }
    }
}
