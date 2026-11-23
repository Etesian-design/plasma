// A window's app actions, for the header. Two ways, by app:
//   menu     (Kate, KWrite, any listed app without a known toolbar): read from the menu the app exports (com.canonical.dbusmenu;
//            KDecoration3 gives its address). Only the actions a toolbar usually carries are picked (New, Open, Save, Undo,
//            Redo, by their icon names); a click sends the menu item's "clicked" event.
//   toolbar  (Dolphin, Okular, Gwenview): the buttons of the app's own main toolbar (its default ui.rc, or the user's own in
//            ~/.local/share/kxmlgui5), driven through the actions KDE apps export on D-Bus (/<app>/<window>/actions/<name>,
//            org.qtproject.Qt.QAction): a click triggers the action in that very window, and enabled, checked and visible
//            follow the app live. Toolbar items that are not buttons (Dolphin's location bar, Okular's page number) stay out.
// Either way the app runs its own action, and the rows the header replaces (the app's toolbars) are hidden.
#pragma once
#include <QDBusContext>
#include <QList>
#include <QObject>
#include <QString>
#include <QStringList>
#include <QTimer>
#include <QVariantMap>
#include <functional>
#include <optional>

struct AppAction {
    int id = 0;
    QString icon;
    QString label;
    bool enabled = true;
    bool checkable = false;
    bool checked = false;
    bool visible = true;
    QString path;    // toolbar mode: the action's D-Bus object, or empty for an action only the app's menu has (a KPart's)
    int menuId = -1; // toolbar mode, with no path: the menu item that runs it
};

class AppActions : public QObject, protected QDBusContext
{
    Q_OBJECT
public:
    explicit AppActions(QObject *parent = nullptr);
    /** the window's menu address, its window class (picks the mode) and caption (picks the app's window, when it has several) */
    void setMenu(const QString &service, const QString &path, const QString &windowClass = QString(), const QString &caption = QString());
    QList<AppAction> actions() const { return m_actions; }
    void trigger(int id);
    /** hide (or show again) the app's toolbars, the rows the header replaces (KDE apps: KXmlGuiWindow over D-Bus) */
    void setToolBarHidden(bool hidden);
    /** toolbar mode: an app's main toolbar buttons, as (action name, icon); empty when the app has no known toolbar */
    static QList<std::pair<QString, QString>> toolbarOf(const QString &windowClass);

Q_SIGNALS:
    void changed();

private Q_SLOTS:
    void refresh();
    void actionChanged(const QString &iface, const QVariantMap &changed, const QStringList &invalidated);
    /** toolbar mode: read the actions' state again (Qt sends no PropertiesChanged for an exported QAction, so the app's menu
     *  signals and caption changes, which come with most state changes, are the cue); a burst of cues makes one read */
    void reread();

private:
    void findWindows(std::function<void(const QStringList &)> then);
    void resolve();
    void loadActions(const QString &window);
    void publish();
    void unwatch();

    QString m_service, m_path, m_caption;
    QList<std::pair<QString, QString>> m_toolbar; // toolbar mode: (action name, icon)
    QString m_window;                              // toolbar mode: the app's window object this header drives
    QList<AppAction> m_loaded;                     // toolbar mode: every action found, in toolbar order (hidden ones too)
    QList<AppAction> m_actions;
    std::optional<bool> m_toolBarHidden; // unknown until the first call, which is always sent
    // The app's window can reach D-Bus after its menu: the toolbar state is sent again until one window has taken it, and the
    // window is looked for again until it is there.
    void applyToolBar();
    QTimer m_retry, m_resolveRetry, m_reread;
    int m_tries = 0, m_resolveTries = 0;
    bool m_applied = false;
    int m_generation = 0;
};
