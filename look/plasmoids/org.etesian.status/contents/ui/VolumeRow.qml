import QtQuick
import org.kde.plasma.private.volume

SliderRow {
    icon: "audio-volume-high-symbolic"
    readonly property var sink: PreferredDevice.sink
    /** false hides this part of the menu */
    property bool available: sink !== null
    to: PulseAudio.NormalVolume
    value: sink ? sink.volume : 0
    onMoved: (v) => { if (sink) { sink.muted = false; sink.volume = v } }
}
