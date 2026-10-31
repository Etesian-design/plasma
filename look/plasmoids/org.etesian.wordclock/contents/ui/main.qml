/*
 * Belle's word clock on the desktop (belle/BelleWidget.vue .bw-word; the phone's BelleWordClockWidget): the 12-hour hour in
 * words, large, the minutes under it in magenta ("O'Clock" on the hour, "Oh Five"), then the date. 4 × 2 cells.
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

    readonly property var ones: ["", "One", "Two", "Three", "Four", "Five", "Six", "Seven", "Eight", "Nine", "Ten",
        "Eleven", "Twelve", "Thirteen", "Fourteen", "Fifteen", "Sixteen", "Seventeen", "Eighteen", "Nineteen"]
    readonly property var tens: ["", "", "Twenty", "Thirty", "Forty", "Fifty"]
    function words(n) { return n < 20 ? ones[n] : [tens[Math.floor(n / 10)], ones[n % 10]].filter(w => w).join(" ") }
    function minuteWords(m) { return m === 0 ? "O'Clock" : m < 10 ? "Oh " + ones[m] : words(m) }

    fullRepresentation: Column {
        leftPadding: 16; topPadding: 18
        Text { text: root.words(root.now.getHours() % 12 || 12); color: "white"; font.pixelSize: 72; lineHeight: 0.9; style: Text.Raised; styleColor: "#88000000" }
        Text { text: root.minuteWords(root.now.getMinutes()); color: "#E0287A"; font.pixelSize: 40; style: Text.Raised; styleColor: "#88000000" }
        Text { topPadding: 10; text: Qt.formatDate(root.now, "dd/MM/yyyy"); color: "white"; font.pixelSize: 26; style: Text.Raised; styleColor: "#88000000" }
    }
}
