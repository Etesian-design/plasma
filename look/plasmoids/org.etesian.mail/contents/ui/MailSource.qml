// The widget's mail source, or null when it cannot be had: KMail needs the Etesian mail plugin (look/mail, built and
// installed by install.sh), loaded here only if present so the widget still shows without it.
import QtQuick

QtObject {
    id: src
    property string source: "kmail"
    property string account: ""
    readonly property var inbox: make(source)
    readonly property string missing: inbox ? "" : "KMail mails need the Etesian mail plugin. Run install.sh again to build it."
    function make(kind) {
        if (kind !== "kmail") return null
        try {
            return Qt.createQmlObject('import org.etesian.mail; KMailInbox { }', src, "MailSource.qml")
        } catch (e) {
            return null
        }
    }
    onAccountChanged: if (inbox) inbox.account = account
    Component.onCompleted: if (inbox) inbox.account = account
}
