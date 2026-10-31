// A window's app actions, read from the menu the app exports (com.canonical.dbusmenu; KDecoration3 gives its address).
// Only the actions a toolbar usually carries are picked (New, Open, Save, Undo, Redo, by their icon names); a click sends the
// menu item's "clicked" event, so the app runs its own action. The list follows the menu: enabled states update live.
#pragma once
#include <QObject>
#include <QList>
#include <QString>
#include <optional>

struct AppAction {
    int id = 0;
    QString icon;
    QString label;
    bool enabled = true;
};

class AppActions : public QObject
{
    Q_OBJECT
public:
    explicit AppActions(QObject *parent = nullptr);
    void setMenu(const QString &service, const QString &path);
    QList<AppAction> actions() const { return m_actions; }
    void trigger(int id);
    /** hide (or show again) the app's toolbars, the rows the header replaces (KDE apps: KXmlGuiWindow over D-Bus) */
    void setToolBarHidden(bool hidden);

Q_SIGNALS:
    void changed();

private Q_SLOTS:
    void refresh();

private:
    QString m_service, m_path;
    QList<AppAction> m_actions;
    std::optional<bool> m_toolBarHidden; // unknown until the first call, which is always sent
};
