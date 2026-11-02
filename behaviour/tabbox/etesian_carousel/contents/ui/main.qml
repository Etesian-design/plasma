/*
 * The Etesian desktop Windows view as a KWin window switcher (etesian-design src/shell/desktop/XWindows.vue).
 * Super+Tab shows the open windows as live cards on a dark scrim: level 1 is the carousel (one large card, its neighbours
 * at the sides), and Down / Up while Super is held zooms out to 2, 3 or 4 cards per row and back.
 * Tab / Shift+Tab and the wheel move, releasing Super switches (KWin does that part: a window switcher never receives the
 * wheel, so wheel-zoom and keeping the view open need a KWin effect instead; see README). Cards keep the window's aspect ratio and the card
 * radius; the app badge is a squircle.
 */
import QtQuick
import QtQuick.Window
import QtQuick.Shapes
import org.kde.kwin as KWin
import org.kde.kirigami as Kirigami

KWin.TabBoxSwitcher {
    id: tabBox

    // Zoom level, kept while KWin keeps this switcher loaded: 1 = carousel, then 2, 3, 4 per row.
    property int level: 1
    readonly property color accent: "#4591FF"   // --hd-color-accent-default
    readonly property int radius: 8              // --hd-radius-card

    // KWin moves the selection (Tab, Shift+Tab); both views follow it, and a click in either view moves it back.
    onCurrentIndexChanged: { view.currentIndex = currentIndex; grid.currentIndex = currentIndex }

    Window {
        id: scrim
        visible: tabBox.visible
        flags: Qt.BypassWindowManagerHint | Qt.FramelessWindowHint
        color: Qt.rgba(0, 0, 0, 0.88)            // --hd-surface-scrim
        x: tabBox.screenGeometry.x; y: tabBox.screenGeometry.y
        width: tabBox.screenGeometry.width; height: tabBox.screenGeometry.height

        // Down = zoom out (more cards per row), Up = zoom in; KWin forwards these keys while the switcher is open.
        Item {
            focus: true
            Keys.onDownPressed: tabBox.level = Math.min(4, tabBox.level + 1)
            Keys.onUpPressed: tabBox.level = Math.max(1, tabBox.level - 1)
        }

        Item {
            id: stage
            anchors { fill: parent; topMargin: 76; bottomMargin: 90; leftMargin: 56; rightMargin: 56 }

            // Level 1: the carousel. The current card is centred; ListView keeps it there as Tab moves.
            ListView {
                id: view
                visible: tabBox.level === 1
                anchors.fill: parent
                orientation: ListView.Horizontal
                model: tabBox.model
                currentIndex: tabBox.currentIndex
                onCurrentIndexChanged: tabBox.currentIndex = currentIndex
                spacing: 64
                interactive: false
                highlightRangeMode: ListView.StrictlyEnforceRange
                preferredHighlightBegin: (width - cardW) / 2
                preferredHighlightEnd: (width + cardW) / 2
                highlightMoveDuration: 180
                readonly property real cardH: height - 34
                readonly property real cardW: Math.min(cardH * 1.5, width - 420)
                delegate: Card {
                    width: view.cardW; height: view.height
                    current: ListView.isCurrentItem
                    scale: current ? 1 : 0.82
                    opacity: current ? 1 : 0.55
                    Behavior on scale { NumberAnimation { duration: 180 } }
                }
            }

            // Levels 2-4: a grid, n cards per row, rows scroll with the selection.
            GridView {
                id: grid
                visible: tabBox.level > 1
                anchors.fill: parent
                model: tabBox.model
                currentIndex: tabBox.currentIndex
                onCurrentIndexChanged: tabBox.currentIndex = currentIndex
                interactive: false
                cellWidth: width / tabBox.level
                cellHeight: cellWidth / 1.6 + 34
                highlightMoveDuration: 0
                delegate: Item {
                    id: cell
                    readonly property bool current: GridView.isCurrentItem // attached props only exist on the delegate root
                    width: grid.cellWidth; height: grid.cellHeight
                    Card { anchors { fill: parent; margins: 16 } current: cell.current }
                }
            }
        }

        Text {
            anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom; bottomMargin: 36 }
            text: "Release Super to switch · ↓ ↑ to zoom"
            color: "#C8C8C8"                     // --hd-surface-scrim-fg-secondary
            font.pixelSize: 15
        }
    }

    // One window: title row (squircle app badge + caption in the light face) over the live thumbnail.
    component Card: Item {
        id: card
        property bool current: false
        readonly property int titleH: 34

        Row {
            id: title
            spacing: 10
            height: card.titleH
            anchors.left: thumb.left
            Squircle {
                size: 26; fill: "#3A3A3A"; anchors.verticalCenter: parent.verticalCenter
                Kirigami.Icon { anchors.centerIn: parent; width: 18; height: 18; source: model.icon }
            }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                width: Math.min(implicitWidth, thumb.width - 40)
                text: model.caption
                elide: Text.ElideRight
                color: "white"
                font { pixelSize: 21; weight: Font.Light }
            }
        }

        // The thumbnail keeps the window's own aspect ratio inside the space left under the title.
        KWin.WindowThumbnail {
            id: thumb
            wId: model.windowId
            readonly property real ratio: implicitHeight > 0 ? implicitWidth / implicitHeight : 1.6
            readonly property real availH: card.height - card.titleH
            width: Math.min(card.width, availH * ratio)
            height: width / ratio
            anchors { top: title.bottom; horizontalCenter: parent.horizontalCenter }
        }
        Rectangle {
            anchors.fill: thumb
            anchors.margins: -3
            radius: tabBox.radius + 3
            color: "transparent"
            border { width: 3; color: card.current ? tabBox.accent : "transparent" }
        }
        MouseArea {
            anchors.fill: parent
            onClicked: tabBox.model.activate(index)
        }
    }

    // The N9 squircle (superellipse, n = 4), drawn as a polygon.
    component Squircle: Shape {
        id: sq
        property real size: 26
        property color fill: "#3A3A3A"
        width: size; height: size
        preferredRendererType: Shape.CurveRenderer
        ShapePath {
            fillColor: sq.fill
            strokeWidth: -1
            PathPolyline {
                path: {
                    const pts = [], r = sq.size / 2
                    for (let i = 0; i <= 64; i++) {
                        const t = i / 64 * 2 * Math.PI, c = Math.cos(t), s = Math.sin(t)
                        pts.push(Qt.point(r + r * Math.sign(c) * Math.sqrt(Math.abs(c)), r + r * Math.sign(s) * Math.sqrt(Math.abs(s))))
                    }
                    return pts
                }
            }
        }
    }
}
