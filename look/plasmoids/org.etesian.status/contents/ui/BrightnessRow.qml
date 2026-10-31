// The first display's brightness (the built-in one on a laptop).
import QtQuick
import org.kde.plasma.private.brightnesscontrolplugin

Item {
    width: 332; height: 34
    /** false hides this part of the menu */
    property bool available: control.isBrightnessAvailable && displays.count > 0
    ScreenBrightnessControl { id: control }
    Repeater {
        id: displays
        model: control.displays
        delegate: SliderRow {
            required property int index
            required property string displayName
            required property int brightness
            required property int maxBrightness
            visible: index === 0
            icon: "brightness-high-symbolic"
            to: maxBrightness; value: brightness
            onMoved: (v) => control.setBrightness(displayName, Math.round(v))
        }
    }
}
