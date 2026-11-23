// ThunderbirdInbox: the newest mails in Thunderbird's inboxes, for the Belle Mail widget, with the same face as KMailInbox.
// Read from the profile's own files (Mail/<account>/Inbox and ImapMail/<account>/INBOX, mbox; Thunderbird keeps IMAP inboxes
// offline by default), so it needs neither Thunderbird running nor KDE PIM. Newest first, at most `limit`.
//
//   account     "" for every account, or one account (its folder under Mail/ or ImapMail/, from `accounts`)
//   accounts    [{id, name}] of the accounts (name: the account's name in Thunderbird, from prefs.js)
//   unread      unread mails in the inboxes shown (X-Mozilla-Status), in the part read (the newest `limit` * 4 mails)
//   available   false when there is no Thunderbird profile with a mail account
//   open(row)   shows that mail in Thunderbird (-1: just Thunderbird); compose() writes a new one
//   profile     a profile folder to read instead of the default one (the tests)
#pragma once

#include <QAbstractListModel>
#include <QDateTime>
#include <QFileSystemWatcher>
#include <QTimer>
#include <QVariantList>
#include <QtQml/qqmlregistration.h>

class ThunderbirdInbox : public QAbstractListModel
{
    Q_OBJECT
    QML_ELEMENT
    Q_PROPERTY(QString account READ account WRITE setAccount NOTIFY accountChanged)
    Q_PROPERTY(int limit READ limit WRITE setLimit NOTIFY limitChanged)
    Q_PROPERTY(QString profile READ profile WRITE setProfile NOTIFY profileChanged)
    Q_PROPERTY(QVariantList accounts READ accounts NOTIFY accountsChanged)
    Q_PROPERTY(QString accountName READ accountName NOTIFY accountsChanged)
    Q_PROPERTY(int unread READ unread NOTIFY unreadChanged)
    Q_PROPERTY(bool available READ available NOTIFY availableChanged)
    Q_PROPERTY(int count READ count NOTIFY countChanged)
    Q_PROPERTY(QString firstFrom READ firstFrom NOTIFY countChanged)
public:
    enum Roles { FromRole = Qt::UserRole + 1, SubjectRole, DateRole, UnreadRole };
    explicit ThunderbirdInbox(QObject *parent = nullptr);

    int rowCount(const QModelIndex &parent = {}) const override;
    QVariant data(const QModelIndex &index, int role) const override;
    QHash<int, QByteArray> roleNames() const override;

    QString account() const { return m_account; }
    void setAccount(const QString &a);
    int limit() const { return m_limit; }
    void setLimit(int l);
    QString profile() const { return m_profileSet; }
    void setProfile(const QString &p);
    QVariantList accounts() const { return m_accounts; }
    QString accountName() const;
    int unread() const { return m_unread; }
    bool available() const { return m_available; }
    int count() const { return m_mails.size(); }
    QString firstFrom() const { return m_mails.isEmpty() ? QString() : m_mails.first().from; }

    Q_INVOKABLE void open(int row);
    Q_INVOKABLE void compose();
    Q_INVOKABLE void refresh();

    /** the profile folder read (the default one, or `profile`); empty when there is none */
    QString profileFolder() const { return findProfile(); }
    /** starts Thunderbird as installed (command, Flatpak or Snap) with these arguments */
    static bool launch(const QStringList &args);
    /** RFC 2047 encoded words (=?utf-8?B?...?=, =?iso-8859-1?Q?...?=) decoded; public for the tests */
    static QString decodeHeader(const QByteArray &raw);

Q_SIGNALS:
    void accountChanged();
    void limitChanged();
    void profileChanged();
    void accountsChanged();
    void unreadChanged();
    void availableChanged();
    void countChanged();

private:
    struct Mail { QString from, subject, messageId; QDateTime date; bool unread; };
    struct Box { QString id, name, path; };
    QString findProfile() const;
    QList<Box> boxes() const;
    void readBox(const QString &path, QList<Mail> &into, int &unread) const;

    QString m_account, m_profileSet, m_profileDir;
    int m_limit = 20;
    QVariantList m_accounts;
    QHash<QString, QString> m_names;
    QList<Mail> m_mails;
    int m_unread = 0;
    bool m_available = false;
    QFileSystemWatcher m_watcher;
    QTimer m_later;
};
