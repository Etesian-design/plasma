// The Etesian splash: the phone's boot screen at rest (vendor/etesian/bootanimation, last frame): black, a soft oval glow,
// the ETESIAN wordmark in Fira Sans Medium (SIL OFL 1.1, images/OFL-FiraSans.txt; no Nokia fonts). It fades out when
// Plasma has started (stage 6).
import QtQuick

Rectangle {
    id: root
    color: "#000000"
    property int stage
    onStageChanged: if (stage === 6) fade.start()

    FontLoader { id: fira; source: "images/FiraSans-Medium.ttf" }

    // the oval glow (a radial gradient squashed into the screen's shape)
    Rectangle {
        anchors.centerIn: parent
        width: parent.width * 1.1; height: parent.height * 1.1
        radius: width / 2
        gradient: Gradient {
            orientation: Gradient.Vertical
            GradientStop { position: 0.0; color: "#000000" }
            GradientStop { position: 0.5; color: "#1A1A1A" }
            GradientStop { position: 1.0; color: "#000000" }
        }
        opacity: 0.9
    }
    Text {
        id: mark
        anchors.centerIn: parent
        text: "ETESIAN"
        color: "#E6E6E6"
        font { family: fira.name; pixelSize: Math.round(root.height * 0.055); letterSpacing: root.height * 0.002 }
        style: Text.Raised; styleColor: "#30FFFFFF"
    }
    OpacityAnimator { id: fade; target: root; from: 1; to: 0; duration: 600; easing.type: Easing.InOutQuad }
}
