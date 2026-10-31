// The org.etesian.mail QML module (KMailInbox is registered by QML_ELEMENT in kmailinbox.h).
#include <QQmlEngineExtensionPlugin>

class EtesianMailPlugin : public QQmlEngineExtensionPlugin
{
    Q_OBJECT
    Q_PLUGIN_METADATA(IID QQmlEngineExtensionInterface_iid)
};

#include "plugin.moc"
