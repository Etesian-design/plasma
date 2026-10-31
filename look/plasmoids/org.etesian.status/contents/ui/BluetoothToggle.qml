import QtQuick
import org.kde.bluezqt as BluezQt

Toggle {
    label: "Bluetooth"; icon: "network-bluetooth-symbolic"
    readonly property var manager: BluezQt.Manager
    on: manager.operational && !manager.bluetoothBlocked
    sub: { const d = manager.devices.filter(d => d.connected); return d.length ? d[0].name : "On" }
    /** false hides this part of the menu */
    property bool available: manager.operational || manager.bluetoothBlocked
    onClicked: manager.bluetoothBlocked = on
}
