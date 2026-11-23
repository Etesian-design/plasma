// SPDX-License-Identifier: AGPL-3.0-only
#include "thunderbirdsearch.h"

#include <QDir>
#include <QSqlDatabase>
#include <QSqlQuery>
#include <QUuid>

static constexpr int MAX_PEOPLE = 6, MAX_MAIL = 6;

ThunderbirdSearch::ThunderbirdSearch(QObject *parent)
    : QAbstractListModel(parent)
{
    // every inbox, deep enough to search (the read stays limited to each inbox's newest part)
    m_inbox.setLimit(400);
    connect(&m_inbox, &QAbstractItemModel::modelReset, this, &ThunderbirdSearch::update);
}

int ThunderbirdSearch::rowCount(const QModelIndex &parent) const
{
    return parent.isValid() ? 0 : m_rows.size();
}

QVariant ThunderbirdSearch::data(const QModelIndex &index, int role) const
{
    if (!index.isValid() || index.row() >= m_rows.size()) return {};
    const Row &r = m_rows[index.row()];
    switch (role) {
    case KindRole: return r.kind;
    case DisplayRole: return r.display;
    case SubtextRole: return r.subtext;
    case IconRole: return r.icon;
    }
    return {};
}

QHash<int, QByteArray> ThunderbirdSearch::roleNames() const
{
    return {{KindRole, "kind"}, {DisplayRole, "display"}, {SubtextRole, "subtext"}, {IconRole, "icon"}};
}

void ThunderbirdSearch::setQuery(const QString &q)
{
    if (q == m_query) return;
    // a new search: read the inboxes again (a profile or account made since the last one is not watched yet); typing on
    // within it only filters what was read
    const bool fresh = m_query.trimmed().size() < 2 && q.trimmed().size() >= 2;
    m_query = q;
    Q_EMIT queryChanged();
    if (fresh) m_inbox.refresh(); // ends in update() (modelReset)
    else update();
}

void ThunderbirdSearch::setProfile(const QString &p)
{
    if (p == m_inbox.profile()) return;
    m_inbox.setProfile(p);
    Q_EMIT profileChanged();
    m_inbox.refresh();
}

/** Contacts whose name or address contains the query, from every address book of the profile (read-only, one at a time). */
QList<ThunderbirdSearch::Row> ThunderbirdSearch::people(const QString &q) const
{
    QList<Row> out;
    const QString dir = m_inbox.profileFolder();
    if (dir.isEmpty() || !QSqlDatabase::isDriverAvailable(QStringLiteral("QSQLITE"))) return out;
    QSet<QString> seen;
    const QStringList books = QDir(dir).entryList({QStringLiteral("abook*.sqlite"), QStringLiteral("history.sqlite")}, QDir::Files, QDir::Name);
    for (const QString &book : books) {
        const QString conn = QStringLiteral("etesian-abook-") + QUuid::createUuid().toString(QUuid::Id128);
        {
            QSqlDatabase db = QSqlDatabase::addDatabase(QStringLiteral("QSQLITE"), conn);
            // read-only and never waiting on Thunderbird's own lock
            db.setConnectOptions(QStringLiteral("QSQLITE_OPEN_READONLY;QSQLITE_BUSY_TIMEOUT=50"));
            db.setDatabaseName(QDir(dir).filePath(book));
            if (db.open()) {
                QSqlQuery s(db);
                // a card's properties are rows (card, name, value): its display name and first address
                s.prepare(QStringLiteral(
                    "SELECT n.value, e.value FROM properties e LEFT JOIN properties n ON n.card = e.card AND n.name = 'DisplayName' "
                    "WHERE e.name = 'PrimaryEmail' AND (e.value LIKE :q ESCAPE '\\' OR n.value LIKE :q ESCAPE '\\') LIMIT 20"));
                QString like = q;
                like.replace(QLatin1Char('\\'), QLatin1String("\\\\")).replace(QLatin1Char('%'), QLatin1String("\\%")).replace(QLatin1Char('_'), QLatin1String("\\_"));
                s.bindValue(QStringLiteral(":q"), QLatin1Char('%') + like + QLatin1Char('%'));
                if (s.exec())
                    while (s.next() && out.size() < MAX_PEOPLE) {
                        const QString name = s.value(0).toString().trimmed(), mail = s.value(1).toString().trimmed();
                        if (mail.isEmpty() || seen.contains(mail.toLower())) continue;
                        seen.insert(mail.toLower());
                        out.append({QStringLiteral("People"), name.isEmpty() ? mail : name, mail, QStringLiteral("im-user"), mail, -1});
                    }
            }
        }
        QSqlDatabase::removeDatabase(conn);
        if (out.size() >= MAX_PEOPLE) break;
    }
    return out;
}

void ThunderbirdSearch::update()
{
    const QString q = m_query.trimmed();
    QList<Row> rows;
    if (q.size() >= 2) {
        rows = people(q);
        int mails = 0;
        for (int i = 0; i < m_inbox.rowCount() && mails < MAX_MAIL; ++i) {
            const QModelIndex ix = m_inbox.index(i);
            const QString from = ix.data(ThunderbirdInbox::FromRole).toString(), subject = ix.data(ThunderbirdInbox::SubjectRole).toString();
            if (!from.contains(q, Qt::CaseInsensitive) && !subject.contains(q, Qt::CaseInsensitive)) continue;
            rows.append({QStringLiteral("Mail"), subject.isEmpty() ? QStringLiteral("(no subject)") : subject, from,
                         ix.data(ThunderbirdInbox::UnreadRole).toBool() ? QStringLiteral("mail-unread") : QStringLiteral("mail-read"), {}, i});
            ++mails;
        }
    }
    const bool changed = rows.size() != m_rows.size();
    beginResetModel();
    m_rows = rows;
    endResetModel();
    if (changed) Q_EMIT countChanged();
}

void ThunderbirdSearch::run(int row)
{
    if (row < 0 || row >= m_rows.size()) return;
    const Row &r = m_rows[row];
    if (r.mail >= 0) m_inbox.open(r.mail);
    else {
        const QString to = r.display == r.address ? r.address : QStringLiteral("%1 <%2>").arg(r.display, r.address);
        ThunderbirdInbox::launch({QStringLiteral("-compose"), QStringLiteral("to='%1'").arg(QString(to).remove(QLatin1Char('\'')))});
    }
}
