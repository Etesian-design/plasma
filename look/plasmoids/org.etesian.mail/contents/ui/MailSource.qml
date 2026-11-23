// The widget's mail source, or null when it cannot be had. Both come from the Etesian mail plugin (look/mail, built and
// installed by install.sh), loaded here only if present so the widget still shows without it:
//   thunderbird  the Thunderbird profile's inboxes (needs only Qt)
//   kmail        KMail's inboxes (needs KDE PIM's Akonadi; the plugin is built without it when Akonadi is missing)
//   auto         Thunderbird when it has a mail account, else KMail
import QtQuick

QtObject {
    id: src
    property string source: "auto"
    property string account: ""
    readonly property var thunderbird: source !== "kmail" ? make("ThunderbirdInbox") : null
    readonly property var kmail: source !== "thunderbird" ? make("KMailInbox") : null
    readonly property var inbox: source === "thunderbird" ? thunderbird : source === "kmail" ? kmail
        : (thunderbird && thunderbird.available) || !kmail ? thunderbird : kmail
    readonly property string app: inbox === kmail && kmail ? "KMail" : "Thunderbird"
    readonly property string missing: inbox ? "" : (source === "kmail" ? "KMail mails need the Etesian mail plugin built with KDE PIM. Run install.sh again to build it."
        : "Mails need the Etesian mail plugin. Run install.sh again to build it.")
    function make(type) {
        try {
            return Qt.createQmlObject('import org.etesian.mail; ' + type + ' { }', src, "MailSource.qml")
        } catch (e) {
            return null
        }
    }
    onAccountChanged: if (inbox) inbox.account = account
    onInboxChanged: if (inbox) inbox.account = account
    Component.onCompleted: if (inbox) inbox.account = account
}
