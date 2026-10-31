/*
 * The first item of the Desktop v2 menu bar (XMenuBar.vue .x-mbar__app): the focused app's name in bold, then the app menus
 * follow (the Global Menu widget). With no window focused it says "Desktop".
 */
import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.taskmanager as TaskManager
import org.kde.kirigami as Kirigami

PlasmoidItem {
    id: root
    preferredRepresentation: fullRepresentation
    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground
    Layout.preferredWidth: metrics.advanceWidth + 14
    Layout.minimumWidth: Layout.preferredWidth

    TextMetrics { id: metrics; text: root.app; font { pixelSize: 13; bold: true } }
    TaskManager.TasksModel {
        id: tasks
        filterByVirtualDesktop: true
        groupMode: TaskManager.TasksModel.GroupDisabled
    }
    /** the active window's app name; a TasksModel row carries AppName and IsActive */
    property string app: "Desktop"
    function refresh() {
        for (let i = 0; i < tasks.count; i++) {
            const idx = tasks.index(i, 0)
            if (tasks.data(idx, TaskManager.AbstractTasksModel.IsActive)) {
                app = tasks.data(idx, TaskManager.AbstractTasksModel.AppName) || tasks.data(idx, Qt.DisplayRole)
                return
            }
        }
        app = "Desktop"
    }
    Connections {
        target: tasks
        function onDataChanged() { root.refresh() }
        function onCountChanged() { root.refresh() }
    }
    Component.onCompleted: refresh()

    fullRepresentation: Text {
        text: root.app
        leftPadding: 8; rightPadding: 6
        verticalAlignment: Text.AlignVCenter
        color: Kirigami.Theme.textColor
        font { pixelSize: 13; bold: true }
    }
}
