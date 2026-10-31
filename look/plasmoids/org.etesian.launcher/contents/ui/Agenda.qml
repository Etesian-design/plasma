// Calendar entries from Plasma's calendar plugins (holidays, astronomical events, KDE PIM calendars when installed).
// Loaded on its own (the module is Plasma's): without it Events simply has no Calendar entries.
import QtQuick
import org.kde.plasma.workspace.calendar as PlasmaCalendar

Item {
    id: agenda
    /** the month shown; entries load a month at a time */
    property date month: new Date()
    /** bumps whenever entries arrive, so bindings that ask for entries update */
    property int revision: 0
    visible: false

    PlasmaCalendar.EventPluginsManager {
        id: plugins
        Component.onCompleted: enabledPlugins = ["holidaysevents", "pimevents", "astronomicalevents"] // missing ones are skipped
    }
    PlasmaCalendar.Calendar {
        id: cal
        displayedDate: agenda.month
        today: new Date()
        Component.onCompleted: daysModel.setPluginsManager(plugins)
    }
    Connections { target: cal.daysModel; function onAgendaUpdated(d) { agenda.revision++ } }
    onMonthChanged: { cal.displayedDate = month; revision++ }

    /** [{ title, allDay, start, end }] on the day */
    function entries(day) {
        void revision
        return (cal.daysModel.eventsForDate(day) || []).map(e => ({ title: e.title, allDay: e.isAllDay, start: e.startDateTime, end: e.endDateTime, description: e.description }))
    }
}
