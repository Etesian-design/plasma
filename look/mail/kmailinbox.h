// KMailInbox: the newest mails in KMail's inboxes (Akonadi), for the Belle Mail widget. Newest first, at most `limit`.
//
//   account     "" for every account, or one account (an Akonadi resource id, from `accounts`)
//   accounts    [{id, name}] of the mail accounts, for the widget's settings
//   unread      unread mails in the inboxes shown
//   count, firstFrom  how many are shown, and the newest one's sender
//   available   false while Akonadi is not running or there is no mail account
//   open(row)   shows that mail in KMail (-1: just KMail); compose() writes a new one
#pragma once

#include <Akonadi/Collection>
#include <Akonadi/Item>
#include <QAbstractListModel>
#include <QDateTime>
#include <QTimer>
#include <QVariantList>
#include <QtQml/qqmlregistration.h>

namespace Akonadi { class Monitor; }

class KMailInbox : public QAbstractListModel
{
    Q_OBJECT
    QML_ELEMENT
    Q_PROPERTY(QString account READ account WRITE setAccount NOTIFY accountChanged)
    Q_PROPERTY(int limit READ limit WRITE setLimit NOTIFY limitChanged)
    Q_PROPERTY(QVariantList accounts READ accounts NOTIFY accountsChanged)
    Q_PROPERTY(QString accountName READ accountName NOTIFY accountsChanged)
    Q_PROPERTY(int unread READ unread NOTIFY unreadChanged)
    Q_PROPERTY(bool available READ available NOTIFY availableChanged)
    Q_PROPERTY(int count READ count NOTIFY countChanged)
    Q_PROPERTY(QString firstFrom READ firstFrom NOTIFY countChanged)
public:
    enum Roles { FromRole = Qt::UserRole + 1, SubjectRole, DateRole, UnreadRole };
    explicit KMailInbox(QObject *parent = nullptr);

    int rowCount(const QModelIndex &parent = {}) const override;
    QVariant data(const QModelIndex &index, int role) const override;
    QHash<int, QByteArray> roleNames() const override;

    QString account() const { return m_account; }
    void setAccount(const QString &a);
    int limit() const { return m_limit; }
    void setLimit(int l);
    QVariantList accounts() const { return m_accounts; }
    QString accountName() const;
    int unread() const { return m_unread; }
    bool available() const { return m_available; }
    int count() const { return m_mails.size(); }
    QString firstFrom() const { return m_mails.isEmpty() ? QString() : m_mails.first().from; }

    Q_INVOKABLE void open(int row);
    Q_INVOKABLE void compose();
    Q_INVOKABLE void refresh();

Q_SIGNALS:
    void accountChanged();
    void limitChanged();
    void accountsChanged();
    void unreadChanged();
    void availableChanged();
    void countChanged();

private:
    struct Mail { Akonadi::Item::Id id; QString from, subject; QDateTime date; bool unread; };
    void fetchCollections();
    void fetchItems(const Akonadi::Collection::List &inboxes);
    void setAvailable(bool a);

    QString m_account;
    int m_limit = 20;
    QVariantList m_accounts;
    QHash<QString, QString> m_names;
    QString m_shownName;
    QList<Mail> m_mails;
    int m_unread = 0;
    bool m_available = false;
    int m_generation = 0;
    QTimer m_later;
    Akonadi::Monitor *m_monitor;
};
