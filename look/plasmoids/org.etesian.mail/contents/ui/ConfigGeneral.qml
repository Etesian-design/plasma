// Mail settings: the source (Thunderbird, KMail, or whichever has an account) and which account's inbox, or every inbox.
import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM

KCM.SimpleKCM {
    id: page
    property string cfg_source
    property string cfg_sourceDefault
    property string cfg_account
    property string cfg_accountDefault
    // its own source, for the account list (only when the mail plugin is there)
    // its own inbox, for the account list, as MailSource.qml picks it (Plasma's settings page does not load MailSource itself)
    function make(type) { try { return Qt.createQmlObject('import org.etesian.mail; ' + type + ' { }', page, "ConfigGeneral.qml") } catch (e) { return null } }
    readonly property string kind: cfg_source || "auto"
    readonly property var thunderbird: make("ThunderbirdInbox")
    readonly property var kmail: make("KMailInbox")
    readonly property var inbox: kind === "thunderbird" ? thunderbird : kind === "kmail" ? kmail
        : (thunderbird && thunderbird.available) || !kmail ? thunderbird : kmail
  Kirigami.FormLayout {
    QQC2.ComboBox {
        Kirigami.FormData.label: "Source:"
        model: [{ text: "Automatic", value: "auto" }, { text: "Thunderbird", value: "thunderbird" }, { text: "KMail", value: "kmail" }]
        textRole: "text"; valueRole: "value"
        Component.onCompleted: currentIndex = Math.max(0, indexOfValue(cfg_source))
        onActivated: cfg_source = currentValue
    }
    QQC2.ComboBox {
        id: account
        Kirigami.FormData.label: "Account:"
        enabled: !!inbox
        model: [{ name: "Every inbox", id: "" }].concat(inbox ? inbox.accounts : [])
        textRole: "name"; valueRole: "id"
        onModelChanged: currentIndex = Math.max(0, indexOfValue(cfg_account))
        onActivated: cfg_account = currentValue
    }
    QQC2.Label { visible: !inbox; text: kind === "kmail" ? "KMail mails need the Etesian mail plugin built with KDE PIM. Run install.sh again to build it." : "Mails need the Etesian mail plugin. Run install.sh again to build it."; wrapMode: Text.Wrap; Layout.maximumWidth: Kirigami.Units.gridUnit * 20 }
  }
}
