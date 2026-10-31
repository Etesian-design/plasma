// A window's live picture (HdTaskCard preview), fitted into `box` in the window's own aspect ratio.
import QtQuick
import org.kde.taskmanager as TaskManager
import org.kde.pipewire as PipeWire
import org.kde.kirigami as Kirigami

Item {
    id: preview
    property var winId
    property size windowSize: Qt.size(16, 10)
    property size box: Qt.size(280, 280)
    property var icon // shown when KWin gives no stream
    readonly property real s: Math.min(box.width / Math.max(1, windowSize.width), box.height / Math.max(1, windowSize.height))
    width: Math.round(windowSize.width * s); height: Math.round(windowSize.height * s)
    Rectangle { anchors.fill: parent; radius: 8; color: Qt.rgba(1, 1, 1, 0.06) }
    TaskManager.ScreencastingRequest { id: cast; uuid: preview.winId ? String(preview.winId) : "" }
    Kirigami.Icon { anchors.centerIn: parent; width: 64; height: 64; source: preview.icon; visible: cast.nodeId <= 0 }
    PipeWire.PipeWireSourceItem { anchors.fill: parent; nodeId: cast.nodeId; visible: cast.nodeId > 0 }
}
