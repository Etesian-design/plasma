// Mail settings: the source (KMail for now) and which account's inbox, or every inbox.
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
    // its own inbox, for the account list (as MailSource.qml: only when the mail plugin is there)
    readonly property var inbox: { try { return Qt.createQmlObject('import org.etesian.mail; KMailInbox { }', page, "ConfigGeneral.qml") } catch (e) { return null } }
  Kirigami.FormLayout {
    QQC2.ComboBox {
        Kirigami.FormData.label: "Source:"
        model: [{ text: "KMail", value: "kmail" }]
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
    QQC2.Label { visible: !inbox; text: "KMail mails need the Etesian mail plugin. Run install.sh again to build it."; wrapMode: Text.Wrap; Layout.maximumWidth: Kirigami.Units.gridUnit * 20 }
  }
}
