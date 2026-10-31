// Focus = Do not disturb for an hour (the menu shows until when).
import QtQuick
import org.kde.notificationmanager as NotificationManager

Toggle {
    label: "Focus"; icon: "notifications-disabled-symbolic"
    NotificationManager.Settings { id: settings }
    property date now: new Date()
    Timer { interval: 30000; running: true; repeat: true; onTriggered: parent.now = new Date() }
    on: settings.notificationsInhibitedUntil > now
    sub: "Until " + Qt.formatTime(settings.notificationsInhibitedUntil, "hh:mm")
    onClicked: {
        settings.notificationsInhibitedUntil = on ? new Date(0) : new Date(Date.now() + 3600 * 1000)
        settings.save()
        now = new Date()
    }
}
