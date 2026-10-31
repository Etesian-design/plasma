// The Etesian login screen (SDDM, Qt 6). The Desktop v2 background; the time large in the light face with the day and date,
// as in Events; the user as a lit squircle (their picture, or initials); a password field; Enter logs in. Below: the session
// and power buttons as squircles. Fira Sans (SIL OFL, fonts/OFL-FiraSans.txt); no Nokia fonts.
import QtQuick
import QtQuick.Controls

Rectangle {
    id: root
    width: 1920; height: 1080
    color: "#000000"
    readonly property color accent: config.accent || "#4591FF"
    readonly property color fgSecondary: "#C8C8C8"
    property int userIndex: userModel.lastIndex >= 0 ? userModel.lastIndex : 0
    property int sessionIndex: sessionModel.lastIndex >= 0 ? sessionModel.lastIndex : 0
    property date now: new Date()
    // the session names, read by role name (the model's role numbers differ between SDDM versions)
    property var sessionNames: []
    Instantiator { model: sessionModel; delegate: QtObject { required property int index; required property string name; Component.onCompleted: { const n = root.sessionNames.slice(); n[index] = name; root.sessionNames = n } } }
    Timer { interval: 1000; running: true; repeat: true; onTriggered: root.now = new Date() }

    FontLoader { id: light; source: "fonts/FiraSans-Light.ttf" }
    FontLoader { id: regular; source: "fonts/FiraSans-Regular.ttf" }
    FontLoader { id: medium; source: "fonts/FiraSans-Medium.ttf" }

    Image { anchors.fill: parent; source: config.background || "background.png"; fillMode: Image.PreserveAspectCrop }

    // the time and date, top left, as in Events
    Column {
        x: 64; y: 56; spacing: 4
        Text { text: Qt.formatTime(root.now, "hh:mm"); color: "white"; font.family: light.name; font.pixelSize: 96 }
        Text { text: Qt.formatDate(root.now, "dddd d MMMM"); color: root.fgSecondary; font.family: regular.name; font.pixelSize: 22 }
    }

    // the user and the password
    Column {
        anchors.centerIn: parent
        spacing: 18
        width: 360

        Repeater {
            model: userModel
            delegate: Item {
                visible: index === root.userIndex
                width: 360; height: visible ? 150 : 0
                required property int index
                required property string name
                required property string realName
                required property string icon
                Item {
                    id: badge
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: 104; height: 104
                    // a lit squircle in the accent with the initials; the user's picture cut to the squircle when there is one
                    Squircle { id: shape; anchors.fill: parent; picture: icon && !/\/sddm\/faces\//.test(icon) ? icon : ""; fillTop: Qt.lighter(root.accent, 1.2); fillBottom: Qt.darker(root.accent, 1.25) }
                    Text {
                        anchors.centerIn: parent; visible: !shape.hasPicture
                        text: (realName || name).split(" ").map(w => w[0]).join("").slice(0, 2).toUpperCase()
                        color: "white"; font.family: medium.name; font.pixelSize: 38
                    }
                }
                Text {
                    anchors { top: badge.bottom; topMargin: 14; horizontalCenter: parent.horizontalCenter }
                    text: realName || name; color: "white"; font.family: light.name; font.pixelSize: 30
                }
            }
        }

        // the password: a dark pill; Enter or the arrow logs in
        Rectangle {
            width: 360; height: 48; radius: 24
            color: Qt.rgba(1, 1, 1, 0.12)
            border.color: password.activeFocus ? root.accent : Qt.rgba(1, 1, 1, 0.18); border.width: password.activeFocus ? 2 : 1
            TextInput {
                id: password
                anchors { left: parent.left; right: go.left; verticalCenter: parent.verticalCenter; leftMargin: 20; rightMargin: 8 }
                echoMode: TextInput.Password; passwordCharacter: "•"
                color: "white"; font.family: regular.name; font.pixelSize: 18
                focus: true
                onAccepted: root.login()
                Text {
                    visible: !parent.text; text: "Password"
                    color: root.fgSecondary; font: parent.font; anchors.verticalCenter: parent.verticalCenter
                }
            }
            Rectangle {
                id: go
                anchors { right: parent.right; rightMargin: 6; verticalCenter: parent.verticalCenter }
                width: 36; height: 36; radius: 18; color: root.accent
                Text { anchors.centerIn: parent; text: "→"; color: "white"; font.pixelSize: 20 }
                MouseArea { anchors.fill: parent; onClicked: root.login() }
            }
        }
        Text {
            id: message
            width: 360; horizontalAlignment: Text.AlignHCenter
            color: root.fgSecondary; font.family: regular.name; font.pixelSize: 15
            text: userModel.count > 1 ? "Tab: next user" : ""
        }
    }

    property var userNames: []
    Instantiator { model: userModel; delegate: QtObject { required property int index; required property string name; Component.onCompleted: { const n = root.userNames.slice(); n[index] = name; root.userNames = n } } }
    function login() { sddm.login(root.userNames[root.userIndex], password.text, root.sessionIndex) }
    Connections {
        target: sddm
        function onLoginFailed() { message.text = "That password did not work"; message.color = "#FF6B6B"; password.selectAll() }
    }
    Keys.onTabPressed: if (userModel.count > 1) root.userIndex = (root.userIndex + 1) % userModel.count

    // session and power, bottom right: squircle buttons with a label on hover
    Row {
        anchors { right: parent.right; bottom: parent.bottom; margins: 40 }
        spacing: 12
        Button2 { label: root.sessionNames[root.sessionIndex] || "Session"; glyph: "▤"; onClicked: root.sessionIndex = (root.sessionIndex + 1) % Math.max(1, sessionModel.rowCount()) }
        Button2 { label: "Sleep"; glyph: "☾"; visible: sddm.canSuspend; onClicked: sddm.suspend() }
        Button2 { label: "Restart"; glyph: "↻"; visible: sddm.canReboot; onClicked: sddm.reboot() }
        Button2 { label: "Shut down"; glyph: "⏻"; visible: sddm.canPowerOff; onClicked: sddm.powerOff() }
    }

    component Button2: Column {
        id: b
        property string label
        property string glyph
        signal clicked()
        spacing: 6
        Squircle {
            anchors.horizontalCenter: parent.horizontalCenter
            width: 48; height: 48
            fillTop: area.containsMouse ? Qt.rgba(1, 1, 1, 0.26) : Qt.rgba(1, 1, 1, 0.14); fillBottom: fillTop
            Text { anchors.centerIn: parent; text: b.glyph; color: "white"; font.pixelSize: 22 }
            MouseArea { id: area; anchors.fill: parent; hoverEnabled: true; onClicked: b.clicked() }
        }
        Text { anchors.horizontalCenter: parent.horizontalCenter; text: b.label; color: root.fgSecondary; font.family: regular.name; font.pixelSize: 13 }
    }

    /** a squircle (superellipse, n = 2.8 as measured on N9 icons) filled top to bottom: thumb-sized shapes are squircles */
    component Squircle: Canvas {
        property color fillTop
        property color fillBottom
        /** a picture to fill the squircle with (cut to it), over the gradient */
        property string picture
        property bool hasPicture: false
        onPictureChanged: { hasPicture = false; if (picture) loadImage(picture) }
        onImageLoaded: { hasPicture = picture !== "" && isImageLoaded(picture); requestPaint() }
        onFillTopChanged: requestPaint()
        onFillBottomChanged: requestPaint()
        onPaint: {
            const c = getContext("2d"); c.reset()
            const g = c.createLinearGradient(0, 0, 0, height); g.addColorStop(0, fillTop); g.addColorStop(1, fillBottom)
            c.beginPath()
            for (let i = 0; i <= 64; i++) {
                const t = i / 64 * 2 * Math.PI, co = Math.cos(t), si = Math.sin(t)
                const x = width / 2 + width / 2 * Math.sign(co) * Math.pow(Math.abs(co), 2 / 2.8)
                const y = height / 2 + height / 2 * Math.sign(si) * Math.pow(Math.abs(si), 2 / 2.8)
                i ? c.lineTo(x, y) : c.moveTo(x, y)
            }
            c.closePath(); c.fillStyle = g; c.fill()
            if (picture && isImageLoaded(picture)) {
                // cover: scale the picture to fill, centred, clipped to the squircle
                const im = c.createImageData(picture), k = Math.max(width / im.width, height / im.height)
                c.save(); c.clip()
                c.drawImage(picture, (width - im.width * k) / 2, (height - im.height * k) / 2, im.width * k, im.height * k)
                c.restore()
            }
        }
    }
}
