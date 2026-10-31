#include "appactions.h"
#include <QDateTime>
#include <QDBusArgument>
#include <QDBusConnection>
#include <QDBusMessage>
#include <QDBusPendingCallWatcher>
#include <QDBusPendingReply>
#include <QDBusVariant>
#include <QRegularExpression>
#include <functional>

// The toolbar actions, in header order (etesian-design desktop2 decorations: New, Open, Save, Undo, Redo).
static const QStringList WANTED = {QStringLiteral("document-new"), QStringLiteral("document-open"), QStringLiteral("document-save"),
                                   QStringLiteral("edit-undo"), QStringLiteral("edit-redo")};

AppActions::AppActions(QObject *parent)
    : QObject(parent)
{
}

void AppActions::setMenu(const QString &service, const QString &path)
{
    if (service == m_service && path == m_path) return;
    auto bus = QDBusConnection::sessionBus();
    const QString iface = QStringLiteral("com.canonical.dbusmenu");
    if (!m_service.isEmpty()) {
        bus.disconnect(m_service, m_path, iface, QStringLiteral("LayoutUpdated"), this, SLOT(refresh()));
        bus.disconnect(m_service, m_path, iface, QStringLiteral("ItemsPropertiesUpdated"), this, SLOT(refresh()));
    }
    m_service = service;
    m_path = path;
    m_toolBarHidden.reset();
    m_actions.clear();
    if (service.isEmpty() || path.isEmpty()) { Q_EMIT changed(); return; }
    bus.connect(service, path, iface, QStringLiteral("LayoutUpdated"), this, SLOT(refresh()));
    bus.connect(service, path, iface, QStringLiteral("ItemsPropertiesUpdated"), this, SLOT(refresh()));
    refresh();
}

/** one menu item, (ia{sv}av), and its children: collects the wanted actions by icon name */
static void collect(const QDBusArgument &arg, QHash<QString, AppAction> &found)
{
    int id = 0;
    QVariantMap props;
    arg.beginStructure();
    arg >> id >> props;
    arg.beginArray();
    while (!arg.atEnd()) {
        QDBusVariant child;
        arg >> child;
        collect(child.variant().value<QDBusArgument>(), found);
    }
    arg.endArray();
    arg.endStructure();
    const QString icon = props.value(QStringLiteral("icon-name")).toString();
    if (WANTED.contains(icon) && !found.contains(icon) && props.value(QStringLiteral("visible"), true).toBool()) {
        QString label = props.value(QStringLiteral("label")).toString().remove(QLatin1Char('_')).remove(QStringLiteral("…"));
        found.insert(icon, {id, icon, label.trimmed(), props.value(QStringLiteral("enabled"), true).toBool()});
    }
}

void AppActions::refresh()
{
    auto msg = QDBusMessage::createMethodCall(m_service, m_path, QStringLiteral("com.canonical.dbusmenu"), QStringLiteral("GetLayout"));
    msg << 0 << -1 << QStringList{QStringLiteral("icon-name"), QStringLiteral("label"), QStringLiteral("enabled"), QStringLiteral("visible")};
    auto *w = new QDBusPendingCallWatcher(QDBusConnection::sessionBus().asyncCall(msg), this);
    const QString service = m_service;
    connect(w, &QDBusPendingCallWatcher::finished, this, [this, w, service] {
        w->deleteLater();
        if (service != m_service || w->isError()) return;
        const QDBusMessage reply = w->reply();
        if (reply.arguments().size() < 2) return;
        QHash<QString, AppAction> found;
        collect(reply.arguments().at(1).value<QDBusArgument>(), found);
        QList<AppAction> list;
        for (const QString &icon : WANTED)
            if (found.contains(icon)) list << found.value(icon);
        m_actions = list;
        Q_EMIT changed();
    });
}

void AppActions::trigger(int id)
{
    auto msg = QDBusMessage::createMethodCall(m_service, m_path, QStringLiteral("com.canonical.dbusmenu"), QStringLiteral("Event"));
    msg << id << QStringLiteral("clicked") << QVariant::fromValue(QDBusVariant(0)) << uint(QDateTime::currentSecsSinceEpoch());
    QDBusConnection::sessionBus().asyncCall(msg);
}

/** Introspects one object without blocking KWin, then hands the XML on. */
static void introspect(QObject *ctx, const QString &service, const QString &path, std::function<void(const QString &)> then)
{
    auto msg = QDBusMessage::createMethodCall(service, path, QStringLiteral("org.freedesktop.DBus.Introspectable"), QStringLiteral("Introspect"));
    auto *w = new QDBusPendingCallWatcher(QDBusConnection::sessionBus().asyncCall(msg), ctx);
    QObject::connect(w, &QDBusPendingCallWatcher::finished, ctx, [w, then] {
        w->deleteLater();
        QDBusPendingReply<QString> r = *w;
        if (!r.isError()) then(r.value());
    });
}

void AppActions::setToolBarHidden(bool hidden)
{
    if (m_service.isEmpty() || m_toolBarHidden == hidden) return;
    m_toolBarHidden = hidden;
    // The app's main windows are /<app>/MainWindow_<n>; the interface is <app's D-Bus domain>.KXmlGuiWindow. Every window of
    // the app gets the same state (KDE apps keep one toolbar setting per app anyway). All calls are asynchronous: KWin never waits.
    const QString service = m_service;
    introspect(this, service, QStringLiteral("/"), [this, service, hidden](const QString &root) {
        static const QRegularExpression node(QStringLiteral("<node name=\"([^\"]+)\""));
        for (auto m = node.globalMatch(root); m.hasNext();) {
            const QString app = QLatin1Char('/') + m.next().captured(1);
            introspect(this, service, app, [this, service, app, hidden](const QString &xml) {
                static const QRegularExpression win(QStringLiteral("<node name=\"(MainWindow_\\d+)\""));
                for (auto mw = win.globalMatch(xml); mw.hasNext();) {
                    const QString path = app + QLatin1Char('/') + mw.next().captured(1);
                    introspect(this, service, path, [service, path, hidden](const QString &winXml) {
                        static const QRegularExpression ifc(QStringLiteral("<interface name=\"([^\"]+\\.KXmlGuiWindow)\""));
                        const auto mi = ifc.match(winXml);
                        if (!mi.hasMatch()) return;
                        // every toolbar of the window (Kate: mainToolBar and hamburgerBar; the header's … is the app menu)
                        const QString iface = mi.captured(1);
                        auto get = QDBusMessage::createMethodCall(service, path, QStringLiteral("org.freedesktop.DBus.Properties"), QStringLiteral("Get"));
                        get << iface << QStringLiteral("toolBars");
                        auto *w = new QDBusPendingCallWatcher(QDBusConnection::sessionBus().asyncCall(get));
                        QObject::connect(w, &QDBusPendingCallWatcher::finished, w, [w, service, path, iface, hidden] {
                            w->deleteLater();
                            QDBusPendingReply<QDBusVariant> r = *w;
                            if (r.isError()) return;
                            for (const QString &bar : r.value().variant().toStringList()) {
                                auto set = QDBusMessage::createMethodCall(service, path, iface, QStringLiteral("setToolBarVisible"));
                                set << bar << !hidden;
                                QDBusConnection::sessionBus().asyncCall(set);
                            }
                        });
                    });
                }
            });
        }
    });
}
