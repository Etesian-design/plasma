import QtQuick
import org.kde.plasma.networkmanagement as PlasmaNM

Toggle {
    label: "Wi-Fi"; icon: "network-wireless-symbolic"
    on: enabled.wirelessEnabled
    sub: status.networkStatus || "On"
    /** false hides this part of the menu */
    property bool available: enabled.wirelessHwEnabled
    PlasmaNM.EnabledConnections { id: enabled }
    PlasmaNM.NetworkStatus { id: status }
    PlasmaNM.Handler { id: handler }
    onClicked: handler.enableWireless(!enabled.wirelessEnabled)
}
