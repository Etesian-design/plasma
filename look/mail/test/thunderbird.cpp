// SPDX-License-Identifier: AGPL-3.0-only
// The Thunderbird reader against a made-up profile: account names from prefs.js, newest first, read/unread/deleted from
// X-Mozilla-Status, encoded headers, one account or every one, and an inbox growing while watched. Prints PASS/FAIL lines.
#include "../thunderbirdinbox.h"
#include "../thunderbirdsearch.h"

#include <QCoreApplication>
#include <QDir>
#include <QFile>
#include <QSignalSpy>
#include <QSqlDatabase>
#include <QSqlQuery>
#include <QTemporaryDir>
#include <cstdio>

static int failures = 0;
static void expect(const char *what, const QVariant &got, const QVariant &want)
{
    const bool ok = got == want;
    failures += !ok;
    std::printf("%s %s%s\n", ok ? "PASS" : "FAIL", what,
                ok ? "" : qPrintable(QStringLiteral(": got '%1', want '%2'").arg(got.toString(), want.toString())));
}

static QByteArray mail(const char *from, const char *subject, const char *date, const char *status, const char *id)
{
    return QByteArray("From - Mon Nov 23 10:00:00 2026\nX-Mozilla-Status: ") + status + "\nX-Mozilla-Status2: 00000000\nFrom: " + from
        + "\nSubject: " + subject + "\nDate: " + date + "\nMessage-ID: <" + id + ">\n\nBody line\n>From an escaped line\nFrom an unescaped one\n\n";
}

static void write(const QString &path, const QByteArray &data, bool append = false)
{
    QDir().mkpath(path.section(QLatin1Char('/'), 0, -2));
    QFile f(path);
    f.open(append ? QIODevice::Append : QIODevice::WriteOnly);
    f.write(data);
}

int main(int argc, char **argv)
{
    QCoreApplication app(argc, argv);
    QTemporaryDir dir;
    const QString p = dir.path();
    write(p + QStringLiteral("/prefs.js"),
          "user_pref(\"mail.server.server1.directory-rel\", \"[ProfD]ImapMail/imap.example.org\");\n"
          "user_pref(\"mail.server.server1.name\", \"Work\");\n"
          "user_pref(\"mail.server.server2.directory-rel\", \"[ProfD]Mail/Local Folders\");\n"
          "user_pref(\"mail.server.server2.name\", \"Local Folders\");\n");
    write(p + QStringLiteral("/ImapMail/imap.example.org/INBOX"),
          mail("\"Ann Lee\" <ann@example.org>", "=?UTF-8?B?Q2Fmw6k=?= =?UTF-8?Q?_tomorrow?=", "Sun, 22 Nov 2026 09:00:00 +0000", "0000", "a@x")
              + mail("bob@example.org", "Old and read", "Fri, 20 Nov 2026 09:00:00 +0000", "0001", "b@x")
              + mail("Spam <s@example.org>", "Deleted", "Sun, 22 Nov 2026 12:00:00 +0000", "0009", "c@x"));
    write(p + QStringLiteral("/Mail/Local Folders/Inbox"),
          mail("=?iso-8859-1?Q?J=F6rg?= <j@example.org>", "Hello", "Sat, 21 Nov 2026 09:00:00 +0000", "0000", "d@x"));

    ThunderbirdInbox in;
    in.setProfile(p);
    in.refresh();
    expect("available", in.available(), true);
    expect("two accounts", in.accounts().size(), 2);
    QString work;
    for (const QVariant &a : in.accounts())
        if (a.toMap().value(QStringLiteral("id")) == QLatin1String("ImapMail/imap.example.org")) work = a.toMap().value(QStringLiteral("name")).toString();
    expect("an account is named as in Thunderbird", work, QStringLiteral("Work"));
    expect("deleted mails are left out", in.count(), 3);
    expect("newest first, by display name", in.firstFrom(), QStringLiteral("Ann Lee"));
    expect("encoded subject decoded", in.data(in.index(0), ThunderbirdInbox::SubjectRole), QStringLiteral("Café tomorrow"));
    expect("Q-encoded sender decoded", in.data(in.index(1), ThunderbirdInbox::FromRole), QStringLiteral("Jörg"));
    expect("read mail is not unread", in.data(in.index(2), ThunderbirdInbox::UnreadRole), false);
    expect("unread across inboxes", in.unread(), 2);
    expect("no body line taken for a mail", in.data(in.index(2), ThunderbirdInbox::SubjectRole), QStringLiteral("Old and read"));

    in.setAccount(QStringLiteral("Mail/Local Folders"));
    in.refresh();
    expect("one account only", in.count(), 1);
    expect("account name shown", in.accountName(), QStringLiteral("Local Folders"));
    in.setLimit(1);
    in.setAccount(QString());
    in.refresh();
    expect("at most limit mails", in.count(), 1);

    // a new mail arrives: the watcher reads the inbox again by itself
    QSignalSpy spy(&in, &ThunderbirdInbox::countChanged);
    write(p + QStringLiteral("/ImapMail/imap.example.org/INBOX"),
          mail("Cleo <c@example.org>", "Newest", "Mon, 23 Nov 2026 09:00:00 +0000", "0000", "e@x"), true);
    spy.wait(3000);
    expect("a new mail shows by itself", in.firstFrom(), QStringLiteral("Cleo"));
    expect("and counts as unread", in.unread(), 3);

    // search: people from an address book (Thunderbird's layout: properties(card, name, value)), mail by sender or subject
    {
        QSqlDatabase db = QSqlDatabase::addDatabase(QStringLiteral("QSQLITE"), QStringLiteral("make"));
        db.setDatabaseName(p + QStringLiteral("/abook.sqlite"));
        db.open();
        QSqlQuery q(db);
        q.exec(QStringLiteral("CREATE TABLE properties (card TEXT, name TEXT, value TEXT)"));
        q.exec(QStringLiteral("INSERT INTO properties VALUES ('1','DisplayName','Ann Lee'),('1','PrimaryEmail','ann@example.org'),"
                              "('2','DisplayName','Bob 100%'),('2','PrimaryEmail','bob@example.org'),('3','PrimaryEmail','nameless@example.org')"));
        db.close();
    }
    QSqlDatabase::removeDatabase(QStringLiteral("make"));
    ThunderbirdSearch search;
    search.setProfile(p);
    search.setQuery(QStringLiteral("ann"));
    expect("search: a person by name", search.data(search.index(0), ThunderbirdSearch::DisplayRole), QStringLiteral("Ann Lee"));
    expect("search: shown under People", search.data(search.index(0), ThunderbirdSearch::KindRole), QStringLiteral("People"));
    expect("search: and her mail under Mail", search.data(search.index(1), ThunderbirdSearch::DisplayRole), QStringLiteral("Café tomorrow"));
    expect("search: nothing else", search.count(), 2);
    search.setQuery(QStringLiteral("nameless"));
    expect("search: a person by address only", search.data(search.index(0), ThunderbirdSearch::DisplayRole), QStringLiteral("nameless@example.org"));
    search.setQuery(QStringLiteral("0%"));
    expect("search: % is a character, not a wildcard", search.data(search.index(0), ThunderbirdSearch::DisplayRole), QStringLiteral("Bob 100%"));
    search.setQuery(QStringLiteral("newest"));
    expect("search: a mail by subject", search.data(search.index(0), ThunderbirdSearch::SubtextRole), QStringLiteral("Cleo"));
    search.setQuery(QStringLiteral("a"));
    expect("search: one letter finds nothing", search.count(), 0);

    ThunderbirdInbox none;
    none.setProfile(p + QStringLiteral("/nothing"));
    none.refresh();
    expect("no profile: not available", none.available(), false);
    return failures ? 1 : 0;
}
