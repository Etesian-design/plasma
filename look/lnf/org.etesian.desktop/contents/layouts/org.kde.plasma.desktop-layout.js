// The Etesian desktop layout (etesian-design src/shell/desktop): a slim global menu bar on top (app menus on the left,
// tray and clock on the right) and a floating icon dock on the left: launcher | apps | trash, all one Etesian dock widget.
const top = new Panel
top.location = "top"
top.height = Math.round(gridUnit * 1.8)
top.floating = false
top.addWidget("org.etesian.appname")
top.addWidget("org.kde.plasma.appmenu")
top.addWidget("org.kde.plasma.panelspacer")
const events = top.addWidget("org.etesian.events")
events.globalShortcut = "Meta+N"
// Super+Space: Search, the compact search (an addition; Super itself opens the Overview, the dock's first widget)
const search = top.addWidget("org.etesian.search")
search.globalShortcut = "Meta+Space"
// The tray keeps other apps' icons; Wi-Fi, Bluetooth, battery and volume live in the Etesian status menu instead, and
// notifications in Events (the notifications applet stays loaded, hidden, because it draws the pop-ups).
const tray = top.addWidget("org.kde.plasma.systemtray")
const trayItems = tray // the tray widget is itself the containment of its items
{
    trayItems.currentConfigGroup = ["General"]
    trayItems.writeConfig("extraItems", ["org.kde.plasma.notifications", "org.kde.plasma.devicenotifier", "org.kde.plasma.clipboard",
        "org.kde.plasma.mediacontroller", "org.kde.plasma.printmanager", "org.kde.plasma.keyboardlayout", "org.kde.plasma.keyboardindicator",
        "org.kde.plasma.manage-inputmethod", "org.kde.plasma.cameraindicator", "org.kde.kdeconnect", "org.kde.plasma.vault"])
    trayItems.writeConfig("hiddenItems", ["org.kde.plasma.notifications", "org.kde.plasma.clipboard"])
    trayItems.writeConfig("knownItems", [])
}
top.addWidget("org.etesian.status")
const clock = top.addWidget("org.kde.plasma.digitalclock")
clock.currentConfigGroup = ["Appearance"]
// "Sat 24 Oct  12:45" at the far right (XMenuBar.vue .x-mbar__clock)
clock.writeConfig("showDate", true)
clock.writeConfig("dateDisplayFormat", "BesideTime")
clock.writeConfig("dateFormat", "custom")
clock.writeConfig("customDateFormat", "ddd d MMM")

const dock = new Panel
dock.location = "left"
dock.floating = true
dock.lengthMode = "fit"
dock.height = 68 // XDock: 44 px icons in 52 px squircle slots, 8 px padding
dock.addWidget("org.etesian.launcher") // Super taps open it too
const apps = dock.addWidget("org.etesian.dock")
apps.currentConfigGroup = ["General"]
apps.writeConfig("launchers", ["applications:org.kde.dolphin.desktop", "applications:org.kde.kate.desktop", "applications:org.kde.konsole.desktop", "applications:systemsettings.desktop"])
