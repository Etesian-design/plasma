// Silent = the output muted.
import QtQuick
import org.kde.plasma.private.volume

Toggle {
    label: "Silent"; icon: "audio-volume-muted-symbolic"
    readonly property var sink: PreferredDevice.sink
    /** false hides this part of the menu */
    property bool available: sink !== null
    on: sink ? sink.muted : false
    sub: "On"
    onClicked: if (sink) sink.muted = !sink.muted
}
