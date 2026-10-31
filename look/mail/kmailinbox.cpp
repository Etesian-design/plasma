#include "kmailinbox.h"

#include <Akonadi/AgentManager>
#include <Akonadi/CollectionFetchJob>
#include <Akonadi/CollectionFetchScope>
#include <Akonadi/CollectionStatistics>
#include <Akonadi/ItemFetchJob>
#include <Akonadi/ItemFetchScope>
#include <Akonadi/MessageFlags>
#include <Akonadi/MessageParts>
#include <Akonadi/Monitor>
#include <Akonadi/ServerManager>
#include <Akonadi/SpecialCollectionAttribute>
#include <KMime/Message>
#include <QDBusConnection>
#include <QDBusConnectionInterface>
#include <QDBusMessage>
#include <QDBusServiceWatcher>
#include <QProcess>
#include <memory>

using namespace Akonadi;

#ifdef KMIME_STD_SHARED_PTR
using MessagePtr = std::shared_ptr<KMime::Message>;
#else
using MessagePtr = KMime::Message::Ptr;
#endif

static const QString kmailService = QStringLiteral("org.kde.kmail");

KMailInbox::KMailInbox(QObject *parent)
    : QAbstractListModel(parent)
    , m_monitor(new Monitor(this))
{
    // Akonadi sends a burst of changes for one new mail or a sync: refetch once they settle.
    m_later.setSingleShot(true);
    m_later.setInterval(700);
    connect(&m_later, &QTimer::timeout, this, &KMailInbox::fetchCollections);
    m_monitor->setMimeTypeMonitored(KMime::Message::mimeType());
    m_monitor->fetchCollection(false);
    auto again = [this] { m_later.start(); };
    connect(m_monitor, &Monitor::itemAdded, this, again);
    connect(m_monitor, &Monitor::itemRemoved, this, again);
    connect(m_monitor, &Monitor::itemChanged, this, again);
    connect(m_monitor, &Monitor::itemMoved, this, again);
    connect(m_monitor, &Monitor::itemsFlagsChanged, this, again);
    connect(m_monitor, &Monitor::collectionAdded, this, again);
    connect(m_monitor, &Monitor::collectionRemoved, this, again);
    connect(m_monitor, &Monitor::collectionStatisticsChanged, this, again);
    connect(ServerManager::self(), &ServerManager::stateChanged, this, [this](ServerManager::State s) {
        if (s == ServerManager::Running)
            m_later.start();
        else if (s == ServerManager::NotRunning || s == ServerManager::Broken)
            setAvailable(false);
    });
    if (ServerManager::isRunning())
        m_later.start();
}

int KMailInbox::rowCount(const QModelIndex &parent) const
{
    return parent.isValid() ? 0 : m_mails.size();
}

QVariant KMailInbox::data(const QModelIndex &index, int role) const
{
    if (!index.isValid() || index.row() >= m_mails.size())
        return {};
    const Mail &m = m_mails[index.row()];
    switch (role) {
    case FromRole:
        return m.from;
    case SubjectRole:
        return m.subject;
    case DateRole:
        return m.date;
    case UnreadRole:
        return m.unread;
    }
    return {};
}

QHash<int, QByteArray> KMailInbox::roleNames() const
{
    return {{FromRole, "from"}, {SubjectRole, "subject"}, {DateRole, "date"}, {UnreadRole, "unread"}};
}

void KMailInbox::setAccount(const QString &a)
{
    if (a == m_account)
        return;
    m_account = a;
    Q_EMIT accountChanged();
    Q_EMIT accountsChanged(); // accountName
    m_later.start();
}

void KMailInbox::setLimit(int l)
{
    l = qBound(1, l, 100);
    if (l == m_limit)
        return;
    m_limit = l;
    Q_EMIT limitChanged();
    m_later.start();
}

QString KMailInbox::accountName() const
{
    return m_account.isEmpty() ? m_shownName : m_names.value(m_account);
}

void KMailInbox::setAvailable(bool a)
{
    if (a == m_available)
        return;
    m_available = a;
    Q_EMIT availableChanged();
}

void KMailInbox::refresh()
{
    fetchCollections();
}

// Every mail folder: the accounts are their resources, the inboxes the folders KMail marks as one (or named Inbox, as IMAP
// accounts have them).
void KMailInbox::fetchCollections()
{
    const int gen = ++m_generation;
    auto job = new CollectionFetchJob(Collection::root(), CollectionFetchJob::Recursive, this);
    job->fetchScope().setContentMimeTypes({KMime::Message::mimeType()});
    job->fetchScope().setIncludeStatistics(true);
    connect(job, &KJob::result, this, [this, job, gen] {
        if (gen != m_generation)
            return;
        if (job->error()) {
            setAvailable(false);
            return;
        }
        QHash<QString, QString> names;
        Collection::List inboxes;
        for (const Collection &c : job->collections()) {
            if (c.isVirtual() || !c.contentMimeTypes().contains(KMime::Message::mimeType())) // not Akonadi's search folders
                continue;
            if (!names.contains(c.resource())) {
                const QString n = AgentManager::self()->instance(c.resource()).name();
                names.insert(c.resource(), n.isEmpty() ? c.resource() : n);
            }
            const auto *special = c.attribute<SpecialCollectionAttribute>();
            const bool inbox = special ? special->collectionType() == "inbox" : c.name().compare(QLatin1String("inbox"), Qt::CaseInsensitive) == 0;
            if (inbox && (m_account.isEmpty() || c.resource() == m_account))
                inboxes << c;
        }
        QVariantList accounts;
        for (auto it = names.cbegin(); it != names.cend(); ++it)
            accounts << QVariantMap{{QStringLiteral("id"), it.key()}, {QStringLiteral("name"), it.value()}};
        std::sort(accounts.begin(), accounts.end(), [](const QVariant &a, const QVariant &b) {
            return a.toMap().value(QStringLiteral("name")).toString().localeAwareCompare(b.toMap().value(QStringLiteral("name")).toString()) < 0;
        });
        if (accounts != m_accounts || names != m_names) {
            m_accounts = accounts;
            m_names = names;
            Q_EMIT accountsChanged();
        }
        // With every inbox shown, the header names the account when only one of them holds mail (KMail always adds an often
        // empty Local Folders).
        int unread = 0;
        QSet<QString> holding;
        for (const Collection &c : inboxes) {
            m_monitor->setCollectionMonitored(c, true);
            unread += qMax<qint64>(0, c.statistics().unreadCount());
            if (c.statistics().count() > 0)
                holding << c.resource();
        }
        const QString shown = holding.size() == 1 ? names.value(*holding.cbegin()) : QString();
        if (shown != m_shownName) {
            m_shownName = shown;
            Q_EMIT accountsChanged();
        }
        if (unread != m_unread) {
            m_unread = unread;
            Q_EMIT unreadChanged();
        }
        setAvailable(!names.isEmpty());
        fetchItems(inboxes);
    });
}

// The newest `limit` mails of each inbox, by their envelopes only (no bodies), merged newest first.
void KMailInbox::fetchItems(const Collection::List &inboxes)
{
    const int gen = m_generation;
    auto mails = std::make_shared<QList<Mail>>();
    auto left = std::make_shared<int>(inboxes.size());
    auto done = [this, mails, gen] {
        if (gen != m_generation)
            return;
        std::sort(mails->begin(), mails->end(), [](const Mail &a, const Mail &b) { return a.date > b.date; });
        if (mails->size() > m_limit)
            mails->resize(m_limit);
        beginResetModel();
        m_mails = *mails;
        endResetModel();
        Q_EMIT countChanged();
    };
    if (inboxes.isEmpty()) {
        done();
        return;
    }
    for (const Collection &c : inboxes) {
        auto job = new ItemFetchJob(c, this);
        job->setLimit(m_limit, 0, Qt::DescendingOrder);
        job->fetchScope().fetchPayloadPart(MessagePart::Envelope);
        job->fetchScope().setAncestorRetrieval(ItemFetchScope::None);
        connect(job, &KJob::result, this, [job, mails, left, done] {
            for (const Item &i : job->items()) {
                if (!i.hasPayload<MessagePtr>())
                    continue;
                const auto msg = i.payload<MessagePtr>();
                Mail m{i.id(), {}, msg->subject()->asUnicodeString(), msg->date()->dateTime(), !i.hasFlag(MessageFlags::Seen)};
                const auto from = msg->from()->mailboxes();
                if (!from.isEmpty())
                    m.from = from.first().hasName() ? from.first().name() : QString::fromUtf8(from.first().address());
                *mails << m;
            }
            if (--*left == 0)
                done();
        });
    }
}

// Shows the mail in KMail: straight away when it runs, else once it has started. Row -1 just opens KMail (a second start
// brings the running one to the front).
void KMailInbox::open(int row)
{
    if (row == -1) {
        QProcess::startDetached(QStringLiteral("kmail"), {});
        return;
    }
    if (row < 0 || row >= m_mails.size())
        return;
    const qint64 id = m_mails[row].id;
    auto show = [id] {
        auto msg = QDBusMessage::createMethodCall(kmailService, QStringLiteral("/KMail"), QStringLiteral("org.kde.kmail.kmail"), QStringLiteral("showMail"));
        msg << id;
        QDBusConnection::sessionBus().asyncCall(msg);
    };
    if (QDBusConnection::sessionBus().interface()->isServiceRegistered(kmailService)) {
        show();
        return;
    }
    auto watcher = new QDBusServiceWatcher(kmailService, QDBusConnection::sessionBus(), QDBusServiceWatcher::WatchForRegistration, this);
    connect(watcher, &QDBusServiceWatcher::serviceRegistered, this, [watcher, show] {
        watcher->deleteLater();
        QTimer::singleShot(500, show); // its /KMail object comes a moment after the name
    });
    QProcess::startDetached(QStringLiteral("kmail"), {});
}

void KMailInbox::compose()
{
    QProcess::startDetached(QStringLiteral("kmail"), {QStringLiteral("--composer")});
}
