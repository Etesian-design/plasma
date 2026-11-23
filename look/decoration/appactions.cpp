#include "appactions.h"
#include <QDateTime>
#include <QDBusArgument>
#include <QDBusConnection>
#include <QDBusMessage>
#include <QDBusPendingCallWatcher>
#include <QDBusPendingReply>
#include <QDBusVariant>
#include <QDir>
#include <QFile>
#include <QRegularExpression>
#include <QSharedPointer>

// Menu mode: the toolbar actions, in header order (etesian-design desktop2 decorations: New, Open, Save, Undo, Redo).
static const QStringList WANTED = {QStringLiteral("document-new"), QStringLiteral("document-open"), QStringLiteral("document-save"),
                                   QStringLiteral("edit-undo"), QStringLiteral("edit-redo")};

// Toolbar mode: each app's main toolbar as its own ui.rc lays it out (dolphinui.rc, okular part.rc, gwenviewui.rc), buttons only:
// the location bar, view settings and zoom menus, the page number and the hamburger menu (the header's … is the app menu) stay
// out. Icons as the apps give them: an action the app does not export on D-Bus (Okular's are its document part's) is found in the
// app's menu by this icon.
struct Known { QString app, rc; QList<std::pair<QString, QString>> buttons; };
static const QList<Known> &known()
{
    static const QList<Known> k = {
        {QStringLiteral("dolphin"), QStringLiteral("dolphin/dolphinui.rc"),
         {{QStringLiteral("go_back"), QStringLiteral("go-previous")}, {QStringLiteral("go_forward"), QStringLiteral("go-next")},
          {QStringLiteral("split_view"), QStringLiteral("view-split-left-right")}, {QStringLiteral("split_stash"), QStringLiteral("folder-stash")},
          {QStringLiteral("toggle_search"), QStringLiteral("edit-find")}}},
        {QStringLiteral("okular"), QStringLiteral("okular/part.rc"),
         {{QStringLiteral("show_leftpanel"), QStringLiteral("sidebar-expand-left")}, {QStringLiteral("view_zoom_in"), QStringLiteral("zoom-in")},
          {QStringLiteral("view_zoom_out"), QStringLiteral("zoom-out")}, {QStringLiteral("mouse_drag"), QStringLiteral("transform-browse")},
          {QStringLiteral("mouse_selecttools"), QStringLiteral("select-rectangular")}}},
        {QStringLiteral("gwenview"), QStringLiteral("gwenview/gwenviewui.rc"),
         {{QStringLiteral("go_start_page"), QStringLiteral("go-home")}, {QStringLiteral("browse"), QStringLiteral("view-list-icons")},
          {QStringLiteral("view"), QStringLiteral("view-preview")}, {QStringLiteral("go_previous"), QStringLiteral("go-previous-view")},
          {QStringLiteral("go_next"), QStringLiteral("go-next-view")}, {QStringLiteral("toggle_operations_sidebar"), QStringLiteral("view-right-new")},
          {QStringLiteral("share"), QStringLiteral("document-share")}, {QStringLiteral("fullscreen"), QStringLiteral("view-fullscreen")}}},
    };
    return k;
}

/** Icons for actions a user may add to their own toolbar (standard KDE action names). */
static QString standardIcon(const QString &name)
{
    static const QHash<QString, QString> icons = {
        {QStringLiteral("go_up"), QStringLiteral("go-up")}, {QStringLiteral("go_home"), QStringLiteral("go-home")},
        {QStringLiteral("view_redisplay"), QStringLiteral("view-refresh")}, {QStringLiteral("new_tab"), QStringLiteral("tab-new")},
        {QStringLiteral("create_dir"), QStringLiteral("folder-new")}, {QStringLiteral("open_terminal"), QStringLiteral("utilities-terminal")},
        {QStringLiteral("show_preview"), QStringLiteral("view-preview")}, {QStringLiteral("icons"), QStringLiteral("view-list-icons")},
        {QStringLiteral("compact"), QStringLiteral("view-list-details")}, {QStringLiteral("details"), QStringLiteral("view-list-tree")},
        {QStringLiteral("edit_undo"), QStringLiteral("edit-undo")}, {QStringLiteral("edit_redo"), QStringLiteral("edit-redo")},
        {QStringLiteral("edit_cut"), QStringLiteral("edit-cut")}, {QStringLiteral("edit_copy"), QStringLiteral("edit-copy")},
        {QStringLiteral("edit_paste"), QStringLiteral("edit-paste")}, {QStringLiteral("edit_find"), QStringLiteral("edit-find")},
        {QStringLiteral("file_open"), QStringLiteral("document-open")}, {QStringLiteral("file_print"), QStringLiteral("document-print")},
        {QStringLiteral("file_save"), QStringLiteral("document-save")}, {QStringLiteral("movetotrash"), QStringLiteral("user-trash")},
        {QStringLiteral("properties"), QStringLiteral("document-properties")}, {QStringLiteral("rotate_left"), QStringLiteral("object-rotate-left")},
        {QStringLiteral("rotate_right"), QStringLiteral("object-rotate-right")}, {QStringLiteral("first_page"), QStringLiteral("go-top")},
        {QStringLiteral("last_page"), QStringLiteral("go-bottom")}, {QStringLiteral("go_previous_page"), QStringLiteral("go-previous")},
        {QStringLiteral("go_next_page"), QStringLiteral("go-next")}, {QStringLiteral("view_zoom_in"), QStringLiteral("zoom-in")},
        {QStringLiteral("view_zoom_out"), QStringLiteral("zoom-out")}, {QStringLiteral("fullscreen"), QStringLiteral("view-fullscreen")},
    };
    return icons.value(name);
}

QList<std::pair<QString, QString>> AppActions::toolbarOf(const QString &windowClass)
{
    const QStringList parts = windowClass.toLower().split(QLatin1Char(' '), Qt::SkipEmptyParts);
    for (const Known &k : known()) {
        bool match = false;
        for (const QString &p : parts) match |= p == k.app || p == QStringLiteral("org.kde.") + k.app;
        if (!match) continue;
        // the user's own toolbar, when they changed it (Configure Toolbars saves the whole ui.rc there)
        QFile own(QDir::homePath() + QStringLiteral("/.local/share/kxmlgui5/") + k.rc);
        if (!own.open(QIODevice::ReadOnly)) return k.buttons;
        const QString xml = QString::fromUtf8(own.readAll());
        static const QRegularExpression bar(QStringLiteral(R"re(<ToolBar[^>]*name="mainToolBar"[^>]*>([\s\S]*?)</ToolBar>)re"));
        static const QRegularExpression act(QStringLiteral(R"re(<Action\s+name="([^"]+)")re"));
        const auto b = bar.match(xml);
        if (!b.hasMatch()) return k.buttons;
        QHash<QString, QString> icons;
        for (const auto &[n, i] : k.buttons) icons.insert(n, i);
        QList<std::pair<QString, QString>> out;
        for (auto m = act.globalMatch(b.captured(1)); m.hasNext();) {
            const QString n = m.next().captured(1);
            const QString icon = icons.value(n, standardIcon(n));
            if (!icon.isEmpty()) out.append({n, icon}); // the rest are widgets or menus, or have no known icon
        }
        return out;
    }
    return {};
}

AppActions::AppActions(QObject *parent)
    : QObject(parent)
{
    m_resolveRetry.setInterval(500);
    connect(&m_resolveRetry, &QTimer::timeout, this, &AppActions::resolve);
    m_reread.setSingleShot(true);
    m_reread.setInterval(120);
    connect(&m_reread, &QTimer::timeout, this, [this] {
        if (!m_window.isEmpty() && !m_loaded.isEmpty()) loadActions(m_window);
    });
}

void AppActions::unwatch()
{
    auto bus = QDBusConnection::sessionBus();
    const QString menu = QStringLiteral("com.canonical.dbusmenu");
    if (!m_service.isEmpty()) {
        bus.disconnect(m_service, m_path, menu, QStringLiteral("LayoutUpdated"), this, SLOT(refresh()));
        bus.disconnect(m_service, m_path, menu, QStringLiteral("ItemsPropertiesUpdated"), this, SLOT(refresh()));
        bus.disconnect(m_service, m_path, menu, QStringLiteral("LayoutUpdated"), this, SLOT(reread()));
        bus.disconnect(m_service, m_path, menu, QStringLiteral("ItemsPropertiesUpdated"), this, SLOT(reread()));
    }
    for (const AppAction &a : std::as_const(m_loaded))
        bus.disconnect(m_service, a.path, QStringLiteral("org.freedesktop.DBus.Properties"), QStringLiteral("PropertiesChanged"), this,
                       SLOT(actionChanged(QString, QVariantMap, QStringList)));
}

void AppActions::setMenu(const QString &service, const QString &path, const QString &windowClass, const QString &caption)
{
    const auto toolbar = service.isEmpty() ? QList<std::pair<QString, QString>>() : toolbarOf(windowClass);
    if (service == m_service && path == m_path && toolbar == m_toolbar) {
        if (caption != m_caption) { m_caption = caption; reread(); } // a new folder, page or image: states change with it
        return;
    }
    unwatch();
    ++m_generation;
    m_service = service;
    m_path = path;
    m_caption = caption;
    m_toolbar = toolbar;
    m_window.clear();
    m_loaded.clear();
    m_toolBarHidden.reset();
    m_applied = false;
    m_retry.stop();
    m_resolveRetry.stop();
    m_actions.clear();
    if (service.isEmpty() || path.isEmpty()) { Q_EMIT changed(); return; }
    if (!m_toolbar.isEmpty()) {
        auto bus = QDBusConnection::sessionBus();
        bus.connect(service, path, QStringLiteral("com.canonical.dbusmenu"), QStringLiteral("LayoutUpdated"), this, SLOT(reread()));
        bus.connect(service, path, QStringLiteral("com.canonical.dbusmenu"), QStringLiteral("ItemsPropertiesUpdated"), this, SLOT(reread()));
        m_resolveTries = 0;
        resolve();
        return;
    }
    auto bus = QDBusConnection::sessionBus();
    bus.connect(service, path, QStringLiteral("com.canonical.dbusmenu"), QStringLiteral("LayoutUpdated"), this, SLOT(refresh()));
    bus.connect(service, path, QStringLiteral("com.canonical.dbusmenu"), QStringLiteral("ItemsPropertiesUpdated"), this, SLOT(refresh()));
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
        AppAction a;
        a.id = id;
        a.icon = icon;
        a.label = label.trimmed();
        a.enabled = props.value(QStringLiteral("enabled"), true).toBool();
        found.insert(icon, a);
    }
}

void AppActions::refresh()
{
    auto msg = QDBusMessage::createMethodCall(m_service, m_path, QStringLiteral("com.canonical.dbusmenu"), QStringLiteral("GetLayout"));
    msg << 0 << -1 << QStringList{QStringLiteral("icon-name"), QStringLiteral("label"), QStringLiteral("enabled"), QStringLiteral("visible")};
    auto *w = new QDBusPendingCallWatcher(QDBusConnection::sessionBus().asyncCall(msg), this);
    const int gen = m_generation;
    connect(w, &QDBusPendingCallWatcher::finished, this, [this, w, gen] {
        w->deleteLater();
        if (gen != m_generation || w->isError()) return;
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
    if (!m_toolbar.isEmpty()) { // toolbar mode: the id is the action's place in m_loaded
        if (id < 0 || id >= m_loaded.size()) return;
        if (m_loaded[id].path.isEmpty()) { // only in the menu: click its item
            auto ev = QDBusMessage::createMethodCall(m_service, m_path, QStringLiteral("com.canonical.dbusmenu"), QStringLiteral("Event"));
            ev << m_loaded[id].menuId << QStringLiteral("clicked") << QVariant::fromValue(QDBusVariant(0)) << uint(QDateTime::currentSecsSinceEpoch());
            QDBusConnection::sessionBus().asyncCall(ev);
            return;
        }
        auto msg = QDBusMessage::createMethodCall(m_service, m_loaded[id].path, QStringLiteral("org.qtproject.Qt.QAction"), QStringLiteral("trigger"));
        QDBusConnection::sessionBus().asyncCall(msg);
        return;
    }
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
        then(r.isError() ? QString() : r.value());
    });
}

static QStringList childNodes(const QString &xml)
{
    static const QRegularExpression node(QStringLiteral("<node name=\"([^\"]+)\""));
    QStringList out;
    for (auto m = node.globalMatch(xml); m.hasNext();) out << m.next().captured(1);
    return out;
}

/** The app's main windows: /<app>/<window> objects with a KXmlGuiWindow interface (Kate: MainWindow_1; Dolphin: Dolphin_1). Hands
 *  on (path, interface) pairs as "path\ninterface" once every candidate has answered. */
void AppActions::findWindows(std::function<void(const QStringList &)> then)
{
    const QString service = m_service;
    const int gen = m_generation;
    introspect(this, service, QStringLiteral("/"), [this, service, gen, then](const QString &root) {
        if (gen != m_generation) return;
        auto found = QSharedPointer<QStringList>::create();
        auto pending = QSharedPointer<int>::create(0);
        auto done = [found, pending, then] { if (--*pending == 0) then(*found); };
        const QStringList apps = childNodes(root);
        for (const QString &a : apps) {
            if (a == QLatin1String("MenuBar") || a == QLatin1String("FileUndoManager") || a == QLatin1String("MainApplication")) continue;
            ++*pending;
            const QString app = QLatin1Char('/') + a;
            introspect(this, service, app, [this, service, app, found, pending, done](const QString &xml) {
                for (const QString &child : childNodes(xml)) {
                    ++*pending;
                    const QString path = app + QLatin1Char('/') + child;
                    introspect(this, service, path, [path, found, done](const QString &winXml) {
                        static const QRegularExpression ifc(QStringLiteral("<interface name=\"([^\"]+\\.KXmlGuiWindow)\""));
                        const auto mi = ifc.match(winXml);
                        if (mi.hasMatch()) *found << path + QLatin1Char('\n') + mi.captured(1);
                        done();
                    });
                }
                done();
            });
        }
        if (*pending == 0) then({});
    });
}

/** Toolbar mode: picks the app's window this header belongs to (the only one, or the one whose title is the caption). */
void AppActions::resolve()
{
    if (m_toolbar.isEmpty() || !m_window.isEmpty()) { m_resolveRetry.stop(); return; }
    if (++m_resolveTries > 30) { m_resolveRetry.stop(); return; } // 15 s: a busy session can be that slow to start an app
    if (!m_resolveRetry.isActive()) m_resolveRetry.start();
    const int gen = m_generation;
    findWindows([this, gen](const QStringList &wins) {
        if (gen != m_generation || !m_window.isEmpty() || wins.isEmpty()) return;
        if (wins.size() == 1) { loadActions(wins.first().section(QLatin1Char('\n'), 0, 0)); return; }
        // several windows: ask each for its title
        for (const QString &w : wins) {
            const QString path = w.section(QLatin1Char('\n'), 0, 0);
            auto get = QDBusMessage::createMethodCall(m_service, path, QStringLiteral("org.freedesktop.DBus.Properties"), QStringLiteral("Get"));
            get << QStringLiteral("org.qtproject.Qt.QWidget") << QStringLiteral("windowTitle");
            auto *pw = new QDBusPendingCallWatcher(QDBusConnection::sessionBus().asyncCall(get), this);
            connect(pw, &QDBusPendingCallWatcher::finished, this, [this, pw, path, gen] {
                pw->deleteLater();
                QDBusPendingReply<QDBusVariant> r = *pw;
                if (r.isError() || gen != m_generation || !m_window.isEmpty()) return;
                QString title = r.value().variant().toString().remove(QStringLiteral("[*]"));
                // KWin adds " <2>" to a caption a second window shares
                const QString caption = QString(m_caption).remove(QRegularExpression(QStringLiteral("\\s*<\\d+>$")));
                if (!title.isEmpty() && (caption == title || caption.startsWith(title) || title.startsWith(caption))) loadActions(path);
            });
        }
    });
}

static AppAction fromProps(const QVariantMap &p, AppAction a)
{
    a.enabled = p.value(QStringLiteral("enabled"), a.enabled).toBool();
    a.checkable = p.value(QStringLiteral("checkable"), a.checkable).toBool();
    a.checked = p.value(QStringLiteral("checked"), a.checked).toBool();
    a.visible = p.value(QStringLiteral("visible"), a.visible).toBool();
    QString tip = p.value(QStringLiteral("toolTip")).toString();
    if (tip.isEmpty()) tip = p.value(QStringLiteral("text")).toString().remove(QLatin1Char('&'));
    if (!tip.isEmpty()) a.label = tip;
    return a;
}

/** Toolbar mode: reads each toolbar action of the window, then follows its changes. */
void AppActions::loadActions(const QString &window)
{
    m_window = window;
    m_resolveRetry.stop();
    const int gen = m_generation;
    auto results = QSharedPointer<QList<std::optional<AppAction>>>::create(m_toolbar.size());
    auto pending = QSharedPointer<int>::create(m_toolbar.size());
    for (int i = 0; i < m_toolbar.size(); ++i) {
        AppAction a;
        a.icon = m_toolbar[i].second;
        a.path = window + QStringLiteral("/actions/") + m_toolbar[i].first;
        auto get = QDBusMessage::createMethodCall(m_service, a.path, QStringLiteral("org.freedesktop.DBus.Properties"), QStringLiteral("GetAll"));
        get << QStringLiteral("org.qtproject.Qt.QAction");
        auto *w = new QDBusPendingCallWatcher(QDBusConnection::sessionBus().asyncCall(get), this);
        connect(w, &QDBusPendingCallWatcher::finished, this, [this, w, a, i, gen, results, pending] {
            w->deleteLater();
            QDBusPendingReply<QVariantMap> r = *w;
            if (!r.isError()) (*results)[i] = fromProps(r.value(), a);
            if (--*pending || gen != m_generation) return;
            // the ones not on D-Bus: from the app's menu, by icon (an action neither has, in this app version, stays out)
            auto menu = QDBusMessage::createMethodCall(m_service, m_path, QStringLiteral("com.canonical.dbusmenu"), QStringLiteral("GetLayout"));
            menu << 0 << -1 << QStringList{QStringLiteral("icon-name"), QStringLiteral("label"), QStringLiteral("enabled"), QStringLiteral("visible"),
                                           QStringLiteral("toggle-type"), QStringLiteral("toggle-state")};
            auto *mw = new QDBusPendingCallWatcher(QDBusConnection::sessionBus().asyncCall(menu), this);
            connect(mw, &QDBusPendingCallWatcher::finished, this, [this, mw, gen, results] {
                mw->deleteLater();
                if (gen != m_generation) return;
                QHash<QString, std::pair<int, QVariantMap>> byIcon;
                if (!mw->isError() && mw->reply().arguments().size() >= 2) {
                    std::function<void(const QDBusArgument &)> walk = [&](const QDBusArgument &arg) {
                        int id = 0;
                        QVariantMap props;
                        arg.beginStructure();
                        arg >> id >> props;
                        arg.beginArray();
                        while (!arg.atEnd()) { QDBusVariant c; arg >> c; walk(c.variant().value<QDBusArgument>()); }
                        arg.endArray();
                        arg.endStructure();
                        const QString icon = props.value(QStringLiteral("icon-name")).toString();
                        if (!icon.isEmpty() && !byIcon.contains(icon)) byIcon.insert(icon, {id, props});
                    };
                    walk(mw->reply().arguments().at(1).value<QDBusArgument>());
                }
                QList<AppAction> loaded;
                for (int k = 0; k < m_toolbar.size(); ++k) {
                    std::optional<AppAction> x = (*results)[k];
                    if (!x && byIcon.contains(m_toolbar[k].second)) {
                        const auto [id, p] = byIcon.value(m_toolbar[k].second);
                        AppAction m;
                        m.icon = m_toolbar[k].second;
                        m.menuId = id;
                        m.label = p.value(QStringLiteral("label")).toString().remove(QLatin1Char('_')).remove(QStringLiteral("…")).trimmed();
                        m.enabled = p.value(QStringLiteral("enabled"), true).toBool();
                        m.visible = p.value(QStringLiteral("visible"), true).toBool();
                        m.checkable = !p.value(QStringLiteral("toggle-type")).toString().isEmpty();
                        m.checked = p.value(QStringLiteral("toggle-state")).toInt() == 1;
                        x = m;
                    }
                    if (x) { loaded << *x; loaded.last().id = loaded.size() - 1; }
                }
            const bool first = m_loaded.isEmpty();
            auto same = [](const AppAction &a, const AppAction &b) {
                return a.path == b.path && a.menuId == b.menuId && a.enabled == b.enabled && a.checked == b.checked && a.visible == b.visible && a.label == b.label;
            };
            if (!first && loaded.size() == m_loaded.size() && std::equal(loaded.cbegin(), loaded.cend(), m_loaded.cbegin(), same)) return;
            m_loaded = loaded;
            if (first) // (apps that do send PropertiesChanged are followed at once)
                for (const AppAction &l : std::as_const(m_loaded))
                    if (!l.path.isEmpty())
                        QDBusConnection::sessionBus().connect(m_service, l.path, QStringLiteral("org.freedesktop.DBus.Properties"), QStringLiteral("PropertiesChanged"),
                                                              this, SLOT(actionChanged(QString, QVariantMap, QStringList)));
            publish();
            });
        });
    }
}

void AppActions::actionChanged(const QString &iface, const QVariantMap &changed, const QStringList &)
{
    if (iface != QLatin1String("org.qtproject.Qt.QAction") || !calledFromDBus()) return;
    const QString path = message().path();
    for (AppAction &a : m_loaded)
        if (a.path == path) {
            const AppAction b = fromProps(changed, a);
            if (b.enabled == a.enabled && b.checked == a.checked && b.visible == a.visible && b.label == a.label) return;
            a = b;
            publish();
            return;
        }
}

void AppActions::reread()
{
    if (!m_toolbar.isEmpty()) m_reread.start();
}

void AppActions::publish()
{
    QList<AppAction> list;
    for (const AppAction &a : std::as_const(m_loaded)) if (a.visible) list << a;
    m_actions = list;
    Q_EMIT changed();
}

void AppActions::setToolBarHidden(bool hidden)
{
    if (m_service.isEmpty() || m_toolBarHidden == hidden) return;
    m_toolBarHidden = hidden;
    m_applied = false;
    m_tries = 0;
    applyToolBar();
}

void AppActions::applyToolBar()
{
    if (m_service.isEmpty() || !m_toolBarHidden || m_applied) { m_retry.stop(); return; }
    // no window has taken it yet: ask again in half a second, for up to 15 s (a busy session can be that slow to start an app)
    if (++m_tries > 30) { m_retry.stop(); return; }
    if (!m_retry.isActive()) {
        m_retry.setInterval(500);
        connect(&m_retry, &QTimer::timeout, this, &AppActions::applyToolBar, Qt::UniqueConnection);
        m_retry.start();
    }
    const bool hidden = *m_toolBarHidden;
    // Every window of the app gets the same state (KDE apps keep one toolbar setting per app anyway). All calls are asynchronous:
    // KWin never waits.
    const QString service = m_service;
    findWindows([this, service, hidden](const QStringList &wins) {
        for (const QString &w : wins) {
            const QString path = w.section(QLatin1Char('\n'), 0, 0), iface = w.section(QLatin1Char('\n'), 1);
            // every toolbar of the window (Kate: mainToolBar and hamburgerBar; the header's … is the app menu)
            auto get = QDBusMessage::createMethodCall(service, path, QStringLiteral("org.freedesktop.DBus.Properties"), QStringLiteral("Get"));
            get << iface << QStringLiteral("toolBars");
            auto *pw = new QDBusPendingCallWatcher(QDBusConnection::sessionBus().asyncCall(get), this);
            QObject::connect(pw, &QDBusPendingCallWatcher::finished, this, [this, pw, service, path, iface, hidden] {
                pw->deleteLater();
                QDBusPendingReply<QDBusVariant> r = *pw;
                if (r.isError()) return;
                const QStringList bars = r.value().variant().toStringList();
                if (bars.isEmpty() || service != m_service || m_toolBarHidden != hidden) return;
                m_applied = true;
                m_retry.stop();
                for (const QString &bar : bars) {
                    auto set = QDBusMessage::createMethodCall(service, path, iface, QStringLiteral("setToolBarVisible"));
                    set << bar << !hidden;
                    QDBusConnection::sessionBus().asyncCall(set);
                }
            });
        }
    });
}
