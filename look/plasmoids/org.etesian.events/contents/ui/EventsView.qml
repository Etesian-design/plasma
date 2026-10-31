/*
 * The phone's Events view (etesian-design XEventsPanel.vue), used by the Events sidebar (Super+N) and as the left column of the
 * Overview (Super): the day and date (a click unfolds the month, days with entries dotted), the time in the light face with the
 * weather beside it, then Notifications, Calendar (the picked day) and Feeds, scrolling and fading out at the bottom.
 * The weather city and the feeds are shared by both (SharedSettings.qml, ~/.config/etesianrc).
 */
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import QtQuick.Effects
import org.kde.kirigami as Kirigami
import org.kde.notificationmanager as NotificationManager

Item {
    id: panel
    /** a notification or feed item was opened: the sidebar or the Overview closes */
    signal opened()

    readonly property color accent: "#4591FF"
    readonly property color fgSecondary: "#C8C8C8"
    readonly property color divider: Qt.rgba(1, 1, 1, 0.16)
    readonly property color pressed: Qt.rgba(1, 1, 1, 0.12)
    property date now: new Date()
    Timer { interval: 1000; running: panel.visible; repeat: true; triggeredOnStart: true; onTriggered: panel.now = new Date() }

    NotificationManager.Notifications {
        id: notes
        showExpired: true
        showDismissed: true
        showJobs: false
        groupMode: NotificationManager.Notifications.GroupDisabled
        sortMode: NotificationManager.Notifications.SortByDate
    }
    readonly property int count: notes.count
    SharedSettings { id: settings }
    /** set by the host while the view is on screen (the sidebar open, the Overview up): the settings are read again then */
    property bool shown: false
    onShownChanged: if (shown) settings.reload()

    // Calendar entries (Agenda.qml, Plasma's calendar plugins) and feeds.
    Loader { id: agenda; source: "Agenda.qml" }
    readonly property bool hasCalendar: agenda.status === Loader.Ready
    function entries(day) { return hasCalendar ? agenda.item.entries(day) : [] }
    Feeds { id: feeds; urls: settings.feeds }
    function ago(d) {
        const m = Math.round((panel.now - d) / 60000)
        return m < 1 ? "Now" : m < 60 ? m + " min ago" : m < 24 * 60 ? Math.round(m / 60) + " h ago" : m < 48 * 60 ? "Yesterday" : Qt.formatDate(d, "d MMM")
    }

        property bool month: false
        property int picked: panel.now.getDate()
        readonly property date pickedDate: new Date(panel.now.getFullYear(), panel.now.getMonth(), picked)

        // Day and date; a click folds the month out.
        MouseArea {
            id: dateButton
            width: parent.width; height: 52
            hoverEnabled: true
            onClicked: panel.month = !panel.month
            Rectangle { anchors { fill: parent; leftMargin: 6; rightMargin: 6; topMargin: 4 } radius: 8; color: panel.pressed; visible: parent.containsMouse }
            Column {
                x: 14; anchors.verticalCenter: parent.verticalCenter; spacing: 4
                Text { text: Qt.formatDate(panel.now, "dddd"); color: "white"; font { pixelSize: 16; bold: true } }
                Row {
                    spacing: 6
                    Text { text: Qt.formatDate(panel.now, "d MMMM yyyy"); color: panel.fgSecondary; font.pixelSize: 13 }
                    Kirigami.Icon { width: 16; height: 16; source: panel.month ? "arrow-down" : "arrow-right"; color: panel.fgSecondary; isMask: true }
                }
            }
        }

        Flickable {
            id: scroller
            anchors { left: parent.left; right: parent.right; top: dateButton.bottom; bottom: parent.bottom }
            contentHeight: body.implicitHeight + 56
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            QQC2.ScrollBar.vertical: QQC2.ScrollBar {}
            // .x-ev__feed: the list fades out over its last 56 px
            layer.enabled: true
            layer.effect: MultiEffect {
                maskEnabled: true
                maskSource: ShaderEffectSource { sourceItem: fade; hideSource: true }
            }

            ColumnLayout {
                id: body
                width: scroller.width
                spacing: 0

                // The time, large and light, with the weather beside it.
                RowLayout {
                    Layout.leftMargin: 22; Layout.rightMargin: 18; Layout.topMargin: 6; Layout.bottomMargin: 14
                    spacing: 18
                    Text { text: Qt.formatTime(panel.now, "hh:mm"); color: "white"; font { pixelSize: 64; weight: Font.Light } }
                    Item { Layout.fillWidth: true }
                    Weather { cfg: settings }
                }

                MonthGrid { visible: panel.month; Layout.fillWidth: true; today: panel.now; picked: panel.picked; onPickedDay: (d) => panel.picked = d }

                SectionHeader { title: "Notifications" }
                Text {
                    visible: notes.count === 0
                    Layout.leftMargin: 16; Layout.topMargin: 4; Layout.bottomMargin: 6
                    text: "No notifications"; color: panel.fgSecondary; font.pixelSize: 14
                }
                Repeater {
                    model: notes
                    delegate: FeedItem {
                        Layout.fillWidth: true
                        title: model.summary || model.applicationName || ""
                        body: model.body || ""
                        icon: model.applicationIconName || model.iconName || "preferences-desktop-notification-bell"
                        time: panel.ago(model.created)
                        onClicked: { notes.invokeDefaultAction(notes.index(index, 0)); panel.opened() }
                    }
                }

                // Calendar: the picked day (today until another day is picked in the month).
                SectionHeader { title: "Calendar"; visible: panel.hasCalendar }
                Repeater {
                    model: panel.hasCalendar ? panel.entries(panel.pickedDate) : []
                    delegate: FeedItem {
                        required property var modelData
                        Layout.fillWidth: true
                        title: modelData.title
                        readonly property string day: panel.picked === panel.now.getDate() ? "Today" : Qt.formatDate(panel.pickedDate, "ddd d MMM")
                        body: modelData.allDay ? day + ", all day" : day + " " + Qt.formatTime(modelData.start, "hh:mm") + (modelData.description ? ", " + modelData.description : "")
                        time: modelData.allDay ? "All day" : Qt.formatTime(modelData.start, "hh:mm")
                        icon: "view-calendar-symbolic"; iconMask: true
                        accent: "#EF5500"
                    }
                }
                Text {
                    visible: panel.hasCalendar && panel.entries(panel.pickedDate).length === 0
                    Layout.leftMargin: 16; Layout.topMargin: 4; Layout.bottomMargin: 6
                    text: "Nothing on " + Qt.formatDate(panel.pickedDate, "d MMMM"); color: panel.fgSecondary; font.pixelSize: 14
                }

                // Feeds: RSS / Atom, newest first; the field adds one.
                SectionHeader { title: "Feeds" }
                Repeater {
                    model: feeds.items
                    delegate: FeedItem {
                        required property var modelData
                        Layout.fillWidth: true
                        title: modelData.source || modelData.title
                        body: modelData.source ? modelData.title : ""
                        time: modelData.date.getTime() > 0 ? panel.ago(modelData.date) : ""
                        image: modelData.image
                        icon: "application-rss+xml"
                        onClicked: if (modelData.link) { Qt.openUrlExternally(modelData.link); panel.opened() }
                    }
                }
                QQC2.TextField {
                    Layout.fillWidth: true; Layout.leftMargin: 16; Layout.rightMargin: 16; Layout.topMargin: 6
                    placeholderText: feeds.list.length ? "Add another feed (RSS or Atom address)" : "Add a feed: paste an RSS or Atom address"
                    onAccepted: {
                        const u = text.trim()
                        if (/^https?:\/\//.test(u) && feeds.list.indexOf(u) < 0) settings.setFeeds(feeds.list.concat([u]))
                        text = ""
                    }
                }
            }
        }
        // the fade mask: opaque, then transparent over the last 56 px
        Item {
            id: fade
            visible: false
            width: scroller.width; height: scroller.height
            Rectangle { width: parent.width; height: parent.height - 56; color: "black" }
            Rectangle {
                y: parent.height - 56; width: parent.width; height: 56
                gradient: Gradient { GradientStop { position: 0; color: "black" } GradientStop { position: 1; color: "transparent" } }
            }
        }
        /** HdSectionHeader: bold 12 px secondary title, then a hairline to the right edge */
    component SectionHeader: RowLayout {
        property string title
        Layout.fillWidth: true; Layout.margins: 16; Layout.topMargin: 14; Layout.bottomMargin: 6
        spacing: 8
        Text { text: parent.title; color: panel.fgSecondary; font { pixelSize: 12; bold: true } }
        Rectangle { Layout.fillWidth: true; height: 1; color: panel.divider }
    }

    /** HdEventsFeedItem: a 48 px lit squircle with the app icon, bold title, the text (three lines at most), the time in grey */
    component FeedItem: MouseArea {
        id: item
        property string title; property string body; property string icon; property string time
        property color accent: panel.accent
        property string image
        property bool iconMask: false
        implicitHeight: content.implicitHeight + 16
        hoverEnabled: true
        Rectangle { anchors.fill: parent; color: panel.pressed; visible: item.containsMouse }
        RowLayout {
            id: content
            anchors { left: parent.left; right: parent.right; top: parent.top; margins: 8; leftMargin: 16; rightMargin: 16 }
            spacing: 16
            Item {
                Layout.alignment: Qt.AlignTop
                width: 48; height: 48
                Squircle {
                    id: badge
                    visible: !photo.visible
                    size: 48; fill: Qt.darker(item.accent, 1.2); fillFrom: Qt.lighter(item.accent, 1.2)
                    Kirigami.Icon { anchors.centerIn: parent; width: item.iconMask ? 24 : 28; height: width; source: item.icon; isMask: item.iconMask; color: "white" }
                }
                // a feed picture, cut to the squircle (thumbnails are squircles)
                Image {
                    id: photo
                    anchors.fill: parent
                    source: item.image; fillMode: Image.PreserveAspectCrop; asynchronous: true
                    visible: item.image !== "" && status === Image.Ready
                    layer.enabled: visible
                    layer.effect: MultiEffect { maskEnabled: true; maskSource: ShaderEffectSource { sourceItem: photoMask } }
                }
                Squircle { id: photoMask; size: 48; fill: "black"; visible: false; layer.enabled: true }
            }
            ColumnLayout {
                Layout.fillWidth: true; spacing: 2
                Text { Layout.fillWidth: true; text: item.title; color: "white"; elide: Text.ElideRight; font { pixelSize: 16; bold: true } }
                Text { Layout.fillWidth: true; text: item.body; textFormat: Text.StyledText; color: "white"; wrapMode: Text.Wrap; maximumLineCount: 3; elide: Text.ElideRight; font.pixelSize: 14; visible: text !== "" }
                Text { text: item.time; visible: text !== ""; color: panel.fgSecondary; font.pixelSize: 12; Layout.topMargin: 2 }
            }
        }
    }

    /** the month, weeks from Monday; today ringed in the accent, the picked day filled with it (both squircles) */
    component MonthGrid: ColumnLayout {
        id: month
        property date today
        property int picked
        signal pickedDay(int day)
        readonly property int first: (new Date(today.getFullYear(), today.getMonth(), 1).getDay() + 6) % 7
        readonly property int days: new Date(today.getFullYear(), today.getMonth() + 1, 0).getDate()
        spacing: 0
        Text { Layout.leftMargin: 22; Layout.topMargin: 10; Layout.bottomMargin: 8; text: Qt.formatDate(month.today, "MMMM yyyy"); color: "white"; font { pixelSize: 19; weight: Font.Light } }
        Grid {
            Layout.leftMargin: 18; Layout.rightMargin: 18
            columns: 7
            readonly property real cw: (panel.width - 36) / 7
            Repeater {
                model: ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
                Text { width: parent.cw; horizontalAlignment: Text.AlignHCenter; text: modelData; color: panel.fgSecondary; bottomPadding: 6; font { pixelSize: 11; bold: true } }
            }
            Repeater {
                model: month.first + month.days
                Item {
                    readonly property int day: index - month.first + 1
                    width: parent.cw; height: 40
                    opacity: day > 0 ? 1 : 0 // not visible: false, the Grid would close the gap before the 1st
                    enabled: day > 0
                    Squircle {
                        anchors.centerIn: parent; size: 34
                        fill: parent.day === month.picked ? panel.accent : "transparent"
                        stroke: parent.day === month.today.getDate() && parent.day !== month.picked ? panel.accent : "transparent"
                        strokeWidth: 2
                        Text {
                            anchors.centerIn: parent; text: parent.parent.day; color: "white"
                            font { pixelSize: 13; bold: parent.parent.day === month.today.getDate() || parent.parent.day === month.picked }
                        }
                    }
                    // an accent dot under days with Calendar entries (.x-ev__dot)
                    Rectangle {
                        visible: parent.day > 0 && panel.hasCalendar && panel.entries(new Date(month.today.getFullYear(), month.today.getMonth(), parent.day)).length > 0
                        anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom }
                        width: 4; height: 4; radius: 2; color: panel.accent
                    }
                    MouseArea { anchors.fill: parent; onClicked: month.pickedDay(parent.day) }
                }
            }
        }
        Rectangle { Layout.fillWidth: true; Layout.topMargin: 10; height: 1; color: panel.divider }
    }
}
