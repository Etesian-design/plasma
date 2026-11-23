// ThunderbirdSearch: people and mail matching a query, from Thunderbird, for the Etesian search (no KDE PIM needed).
//   people  the profile's address books (abook*.sqlite: Personal, Collected and synced ones): name or address matches
//   mail    the newest mails of every inbox (as ThunderbirdInbox reads them): sender or subject matches
// Rows: {kind ("People" or "Mail"), display, subtext, icon}; run(row) writes to that person, or opens that mail, in Thunderbird.
#pragma once

#include "thunderbirdinbox.h"

#include <QAbstractListModel>
#include <QtQml/qqmlregistration.h>

class ThunderbirdSearch : public QAbstractListModel
{
    Q_OBJECT
    QML_ELEMENT
    Q_PROPERTY(QString query READ query WRITE setQuery NOTIFY queryChanged)
    Q_PROPERTY(QString profile READ profile WRITE setProfile NOTIFY profileChanged)
    Q_PROPERTY(int count READ count NOTIFY countChanged)
public:
    enum Roles { KindRole = Qt::UserRole + 1, DisplayRole, SubtextRole, IconRole };
    explicit ThunderbirdSearch(QObject *parent = nullptr);

    int rowCount(const QModelIndex &parent = {}) const override;
    QVariant data(const QModelIndex &index, int role) const override;
    QHash<int, QByteArray> roleNames() const override;

    QString query() const { return m_query; }
    void setQuery(const QString &q);
    QString profile() const { return m_inbox.profile(); }
    void setProfile(const QString &p);
    int count() const { return m_rows.size(); }

    Q_INVOKABLE void run(int row);
    Q_INVOKABLE void update();

Q_SIGNALS:
    void queryChanged();
    void profileChanged();
    void countChanged();

private:
    struct Row { QString kind, display, subtext, icon, address; int mail = -1; };
    QList<Row> people(const QString &q) const;

    QString m_query;
    ThunderbirdInbox m_inbox;
    QList<Row> m_rows;
};
