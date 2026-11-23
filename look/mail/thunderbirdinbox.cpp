// SPDX-License-Identifier: AGPL-3.0-only
#include "thunderbirdinbox.h"

#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QProcess>
#include <QRegularExpression>
#include <QSettings>
#include <QStringDecoder>
#include <algorithm>

// Only the end of an inbox is read: the newest mails are appended there. Enough for `limit` * 4 mails of usual size.
static constexpr qint64 TAIL = 8 * 1024 * 1024;

ThunderbirdInbox::ThunderbirdInbox(QObject *parent)
    : QAbstractListModel(parent)
{
    // Thunderbird rewrites an inbox in bursts: read it once things settle
    m_later.setSingleShot(true);
    m_later.setInterval(400);
    connect(&m_later, &QTimer::timeout, this, &ThunderbirdInbox::refresh);
    connect(&m_watcher, &QFileSystemWatcher::fileChanged, &m_later, qOverload<>(&QTimer::start));
    connect(&m_watcher, &QFileSystemWatcher::directoryChanged, &m_later, qOverload<>(&QTimer::start));
    m_later.start();
}

int ThunderbirdInbox::rowCount(const QModelIndex &parent) const
{
    return parent.isValid() ? 0 : m_mails.size();
}

QVariant ThunderbirdInbox::data(const QModelIndex &index, int role) const
{
    if (!index.isValid() || index.row() >= m_mails.size()) return {};
    const Mail &m = m_mails[index.row()];
    switch (role) {
    case FromRole: return m.from;
    case SubjectRole: return m.subject;
    case DateRole: return m.date;
    case UnreadRole: return m.unread;
    }
    return {};
}

QHash<int, QByteArray> ThunderbirdInbox::roleNames() const
{
    return {{FromRole, "from"}, {SubjectRole, "subject"}, {DateRole, "date"}, {UnreadRole, "unread"}};
}

void ThunderbirdInbox::setAccount(const QString &a)
{
    if (a == m_account) return;
    m_account = a;
    Q_EMIT accountChanged();
    Q_EMIT accountsChanged(); // accountName
    m_later.start();
}

void ThunderbirdInbox::setLimit(int l)
{
    if (l == m_limit || l < 1) return;
    m_limit = l;
    Q_EMIT limitChanged();
    m_later.start();
}

void ThunderbirdInbox::setProfile(const QString &p)
{
    if (p == m_profileSet) return;
    m_profileSet = p;
    Q_EMIT profileChanged();
    m_later.start();
}

QString ThunderbirdInbox::accountName() const
{
    return m_account.isEmpty() ? QString() : m_names.value(m_account, m_account);
}

/** The default profile: profiles.ini's install default, else the profile marked Default=1, else the first. Native, Flatpak, Snap. */
QString ThunderbirdInbox::findProfile() const
{
    if (!m_profileSet.isEmpty()) return m_profileSet;
    const QString home = QDir::homePath();
    for (const QString &root : {home + QStringLiteral("/.thunderbird"), home + QStringLiteral("/.var/app/org.mozilla.Thunderbird/.thunderbird"),
                                home + QStringLiteral("/snap/thunderbird/common/.thunderbird")}) {
        const QString ini = root + QStringLiteral("/profiles.ini");
        if (!QFileInfo::exists(ini)) continue;
        QSettings s(ini, QSettings::IniFormat);
        QString pick, first, marked;
        for (const QString &g : s.childGroups()) {
            s.beginGroup(g);
            if (g.startsWith(QLatin1String("Install")) && pick.isEmpty()) pick = s.value(QStringLiteral("Default")).toString();
            if (g.startsWith(QLatin1String("Profile"))) {
                const QString path = s.value(QStringLiteral("Path")).toString();
                if (first.isEmpty()) first = path;
                if (s.value(QStringLiteral("Default")).toInt() == 1) marked = path;
            }
            s.endGroup();
        }
        const QString rel = !pick.isEmpty() ? pick : !marked.isEmpty() ? marked : first;
        if (rel.isEmpty()) continue;
        return QDir::isAbsolutePath(rel) ? rel : root + QLatin1Char('/') + rel;
    }
    return {};
}

/** Every account's inbox, named as in Thunderbird (prefs.js: mail.server.<n>.directory-rel and .name). */
QList<ThunderbirdInbox::Box> ThunderbirdInbox::boxes() const
{
    QList<Box> out;
    if (m_profileDir.isEmpty()) return out;
    QHash<QString, QString> names; // "ImapMail/imap.example.org" -> "Work"
    QFile prefs(m_profileDir + QStringLiteral("/prefs.js"));
    if (prefs.open(QIODevice::ReadOnly)) {
        static const QRegularExpression pref(QStringLiteral(R"re(user_pref\("mail\.server\.(\w+)\.(directory-rel|name)",\s*"((?:[^"\\]|\\.)*)"\);)re"));
        QHash<QString, QString> dir, name;
        for (auto m = pref.globalMatch(QString::fromUtf8(prefs.readAll())); m.hasNext();) {
            const auto x = m.next();
            (x.captured(2) == QLatin1String("name") ? name : dir)[x.captured(1)] = x.captured(3).replace(QLatin1String("\\\""), QLatin1String("\""));
        }
        for (auto it = dir.cbegin(); it != dir.cend(); ++it)
            names[QString(it.value()).remove(QStringLiteral("[ProfD]"))] = name.value(it.key());
    }
    for (const auto &[kind, file] : {std::pair{QStringLiteral("Mail"), QStringLiteral("Inbox")}, std::pair{QStringLiteral("ImapMail"), QStringLiteral("INBOX")}}) {
        const QDir d(m_profileDir + QLatin1Char('/') + kind);
        for (const QString &acc : d.entryList(QDir::Dirs | QDir::NoDotAndDotDot, QDir::Name)) {
            const QString path = d.filePath(acc + QLatin1Char('/') + file);
            if (!QFileInfo(path).isFile()) continue; // "Local Folders" with no inbox, or an IMAP inbox not kept offline
            const QString id = kind + QLatin1Char('/') + acc;
            const QString n = names.value(id);
            out.append({id, n.isEmpty() ? acc : n, path});
        }
    }
    return out;
}

QString ThunderbirdInbox::decodeHeader(const QByteArray &raw)
{
    static const QRegularExpression word(QStringLiteral(R"(=\?([^?]+)\?([BbQq])\?([^?]*)\?=)"));
    const QString in = QString::fromUtf8(raw);
    QString out;
    qsizetype at = 0;
    bool lastWasWord = false;
    for (auto it = word.globalMatch(in); it.hasNext();) {
        const auto m = it.next();
        const QString between = in.mid(at, m.capturedStart() - at);
        if (!(lastWasWord && between.trimmed().isEmpty())) out += between; // spaces between two encoded words are dropped
        QByteArray bytes = m.captured(3).toLatin1();
        if (m.captured(2).compare(QLatin1String("B"), Qt::CaseInsensitive) == 0) bytes = QByteArray::fromBase64(bytes);
        else bytes = QByteArray::fromPercentEncoding(bytes.replace('_', ' ').replace('%', "%25").replace('=', '%'));
        QStringDecoder dec(m.captured(1).section(QLatin1Char('*'), 0, 0).toLatin1().constData());
        out += dec.isValid() ? QString(dec(bytes)) : QString::fromLatin1(bytes);
        at = m.capturedEnd();
        lastWasWord = true;
    }
    out += in.mid(at);
    return out.simplified();
}

/** The sender as people read it: the display name, else the address. */
static QString displayName(const QString &from)
{
    static const QRegularExpression named(QStringLiteral(R"re(^\s*"?(.*?)"?\s*<([^>]*)>)re"));
    const auto m = named.match(from);
    if (m.hasMatch()) return m.captured(1).trimmed().isEmpty() ? m.captured(2) : m.captured(1).trimmed();
    return from.trimmed();
}

void ThunderbirdInbox::readBox(const QString &path, QList<Mail> &into, int &unread) const
{
    QFile f(path);
    if (!f.open(QIODevice::ReadOnly)) return;
    const qint64 from = std::max<qint64>(0, f.size() - TAIL);
    f.seek(from);
    QByteArray data = f.readAll();
    // messages start at a "From " line after a blank line (mbox; a body's own "From " lines are escaped as ">From", and an
    // unescaped one in a body still follows text, not a blank line); a cut first message is skipped
    QList<qsizetype> starts;
    if (from == 0 && data.startsWith("From ")) starts << 0;
    for (qsizetype i = data.indexOf("\n\nFrom "); i >= 0; i = data.indexOf("\n\nFrom ", i + 1)) starts << i + 2;
    QList<Mail> mails;
    for (int k = 0; k < starts.size(); ++k) {
        const qsizetype s = starts[k], e = k + 1 < starts.size() ? starts[k + 1] : data.size();
        qsizetype he = data.indexOf("\n\n", s);
        if (he < 0 || he > e) he = e;
        // unfold the header lines, then read the ones wanted
        const QList<QByteArray> lines = data.mid(s, he - s).replace("\r\n", "\n").replace("\n\t", " ").replace("\n ", " ").split('\n');
        QByteArray fromH, subj, date, mid;
        uint status = 0;
        bool hasStatus = false;
        for (const QByteArray &l : lines) {
            const qsizetype c = l.indexOf(':');
            if (c <= 0) continue;
            const QByteArray key = l.left(c).trimmed().toLower(), val = l.mid(c + 1).trimmed();
            if (key == "from" && fromH.isEmpty()) fromH = val;
            else if (key == "subject" && subj.isEmpty()) subj = val;
            else if (key == "date" && date.isEmpty()) date = val;
            else if (key == "message-id" && mid.isEmpty()) mid = val;
            else if (key == "x-mozilla-status" && !hasStatus) { status = val.toUInt(nullptr, 16); hasStatus = true; }
        }
        if (status & 0x0008) continue; // deleted, not yet compacted away
        QString d = QString::fromLatin1(date).section(QLatin1Char('('), 0, 0).trimmed();
        QDateTime when = QDateTime::fromString(d, Qt::RFC2822Date);
        Mail m{displayName(decodeHeader(fromH)), decodeHeader(subj), QString::fromLatin1(mid).remove(QLatin1Char('<')).remove(QLatin1Char('>')), when,
               !(status & 0x0001)};
        mails << m;
    }
    // the newest are at the end; unread counts within what was read
    for (const Mail &m : mails) unread += m.unread;
    into << mails;
}

void ThunderbirdInbox::refresh()
{
    m_profileDir = findProfile();
    const QList<Box> all = boxes();
    QVariantList accounts;
    QHash<QString, QString> names;
    for (const Box &b : all) {
        accounts << QVariantMap{{QStringLiteral("id"), b.id}, {QStringLiteral("name"), b.name}};
        names[b.id] = b.name;
    }
    if (accounts != m_accounts) {
        m_accounts = accounts;
        m_names = names;
        Q_EMIT accountsChanged();
    }
    if (!m_watcher.files().isEmpty()) m_watcher.removePaths(m_watcher.files());
    if (!m_watcher.directories().isEmpty()) m_watcher.removePaths(m_watcher.directories());
    // the profile folders too: an account added, or an inbox replaced by a new file (compaction)
    for (const QString &d : {m_profileDir + QStringLiteral("/Mail"), m_profileDir + QStringLiteral("/ImapMail")})
        if (QFileInfo(d).isDir()) m_watcher.addPath(d);
    QList<Mail> mails;
    int unread = 0;
    for (const Box &b : all) {
        if (!m_account.isEmpty() && b.id != m_account) continue;
        m_watcher.addPath(b.path);
        m_watcher.addPath(QFileInfo(b.path).absolutePath());
        readBox(b.path, mails, unread);
    }
    std::stable_sort(mails.begin(), mails.end(), [](const Mail &a, const Mail &b) { return a.date > b.date; });
    if (mails.size() > m_limit) mails.resize(m_limit);

    const bool countChange = mails.size() != m_mails.size() || (mails.isEmpty() != m_mails.isEmpty())
        || (!mails.isEmpty() && mails.first().from != m_mails.first().from);
    beginResetModel();
    m_mails = mails;
    endResetModel();
    if (countChange) Q_EMIT countChanged();
    if (unread != m_unread) { m_unread = unread; Q_EMIT unreadChanged(); }
    const bool avail = !all.isEmpty();
    if (avail != m_available) { m_available = avail; Q_EMIT availableChanged(); }
}

/** Thunderbird as installed: the command, else the Flatpak, else the Snap. */
bool ThunderbirdInbox::launch(const QStringList &args)
{
    if (QProcess::startDetached(QStringLiteral("thunderbird"), args)) return true;
    if (QProcess::startDetached(QStringLiteral("flatpak"), QStringList{QStringLiteral("run"), QStringLiteral("org.mozilla.Thunderbird")} + args)) return true;
    return QProcess::startDetached(QStringLiteral("snap"), QStringList{QStringLiteral("run"), QStringLiteral("thunderbird")} + args);
}

void ThunderbirdInbox::open(int row)
{
    if (row < 0 || row >= m_mails.size() || m_mails[row].messageId.isEmpty()) { launch({QStringLiteral("-mail")}); return; }
    launch({QStringLiteral("mid:") + m_mails[row].messageId}); // Thunderbird opens a mid: link as that message
}

void ThunderbirdInbox::compose()
{
    launch({QStringLiteral("-compose")});
}
