// An icon and a slider (XStatusPanel .x-stat__row).
import QtQuick
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami

Row {
    id: row
    property string icon
    property alias value: slider.value
    property alias to: slider.to
    signal moved(real value)
    width: 332; height: 34; spacing: 12
    Kirigami.Icon { anchors.verticalCenter: parent.verticalCenter; width: 18; height: 18; source: row.icon; color: "white"; isMask: true }
    QQC2.Slider { id: slider; anchors.verticalCenter: parent.verticalCenter; width: row.width - 30; from: 0; onMoved: row.moved(value) }
}
