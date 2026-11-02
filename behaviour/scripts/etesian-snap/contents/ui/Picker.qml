// The snap-layout picker card (etesian-design src/shell/desktop/XLayoutPicker.vue): 640 px, the six layouts three per row,
// numbered. Shared by the drag overlay (etesian-snap script) and the Super+Z picker (etesian_snaplayouts effect); keep both copies equal.
import QtQuick

Rectangle {
    id: pickerCard
    /** geometry.ts LAYOUTS: {label, zones: [[x, y, w, h] as fractions]} */
    property var layouts: []
    signal picked(int layout, int zone)
    signal cancelled()
    /** [layout, zone] lit by the dragged pointer */
    property var hot: null
    property bool dragMode: false
    property alias keysLayout: pickerKeys.layout
    function focusKeys() { pickerKeys.forceActiveFocus() }
    width: 640; height: pickerCol.implicitHeight + 28
    radius: 8
    color: Qt.rgba(20 / 255, 20 / 255, 20 / 255, 0.96)
    border { width: 1; color: Qt.rgba(1, 1, 1, 0.16) }

    /** [layout, zone] under a point in this card's coordinates, or null */
    function zoneAt(p) {
        for (let i = 0; i < minis.count; i++) {
            const m = minis.itemAt(i).mini, q = m.mapFromItem(pickerCard, p.x, p.y)
            if (q.x < 0 || q.y < 0 || q.x >= m.width || q.y >= m.height) continue
            const zs = pickerCard.layouts[i].zones
            for (let j = 0; j < zs.length; j++) {
                const [fx, fy, fw, fh] = zs[j]
                if (q.x >= fx * m.width && q.x < (fx + fw) * m.width && q.y >= fy * m.height && q.y < (fy + fh) * m.height) return [i, j]
            }
        }
        return null
    }

    Column {
        id: pickerCol
        x: 18; y: 16; width: parent.width - 36
        spacing: 12
        Row {
            spacing: 10
            Text { text: "Snap layouts"; color: "white"; font { pixelSize: 21; weight: Font.Light } }
            Text { anchors.verticalCenter: parent.verticalCenter; text: "Super+Z"; color: "#C8C8C8"; font { pixelSize: 11; bold: true } }
        }
        Grid {
            columns: 3; columnSpacing: 16; rowSpacing: 14
            Repeater {
                id: minis
                model: pickerCard.layouts
                Column {
                    id: item
                    required property var modelData
                    required property int index
                    readonly property Item mini: miniBox
                    width: (pickerCol.width - 32) / 3; spacing: 6
                    Item {
                        id: miniBox
                        width: parent.width; height: 90
                        Repeater {
                            model: item.modelData.zones
                            Rectangle {
                                required property var modelData
                                required property int index
                                readonly property bool lit: pickerCard.hot && pickerCard.hot[0] === item.index && pickerCard.hot[1] === index
                                    || pickerKeys.layout === item.index
                                x: modelData[0] * miniBox.width + 3; y: modelData[1] * miniBox.height + 3
                                width: modelData[2] * miniBox.width - 6; height: modelData[3] * miniBox.height - 6
                                radius: 5
                                color: lit || zoneMouse.containsMouse ? "#4591FF" : Qt.rgba(1, 1, 1, 0.22)
                                Text { visible: pickerKeys.layout === item.index; anchors.centerIn: parent; text: index + 1; color: "white"; font.bold: true }
                                MouseArea {
                                    id: zoneMouse
                                    anchors.fill: parent; hoverEnabled: true
                                    onClicked: pickerCard.picked(item.index, index)
                                }
                            }
                        }
                    }
                    Row {
                        spacing: 6
                        Rectangle {
                            width: 16; height: 16; radius: 3; color: "transparent"; border { width: 1; color: Qt.rgba(1, 1, 1, 0.16) }
                            Text { anchors.centerIn: parent; text: item.index + 1; color: "white"; font { pixelSize: 10; bold: true } }
                        }
                        Text { text: item.modelData.label; color: "#C8C8C8"; font.pixelSize: 12 }
                    }
                }
            }
        }
        Rectangle { width: parent.width; height: 1; color: Qt.rgba(1, 1, 1, 0.16) }
        Text {
            color: "#C8C8C8"; font.pixelSize: 12
            text: pickerCard.dragMode ? "Release over a zone to snap there · drag down to keep the window floating"
                                     : "1–6 layout, then the zone number · Esc cancels"
        }
    }

    // Super+Z: digits pick a layout, then its zone.
    Item {
        id: pickerKeys
        property int layout: -1
        focus: true
        Keys.onPressed: (e) => {
            if (e.key === Qt.Key_Escape) { pickerCard.cancelled(); return }
            const n = e.key - Qt.Key_1
            if (n < 0 || n > 8) return
            if (layout < 0) { if (n < pickerCard.layouts.length) layout = n }
            else if (n < pickerCard.layouts[layout].zones.length) pickerCard.picked(layout, n)
            e.accepted = true
        }
    }
}
