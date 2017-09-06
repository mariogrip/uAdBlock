#include <QtQml>
#include <QtQml/QQmlContext>
#include "backend.h"
#include "cmd.h"


void BackendPlugin::registerTypes(const char *uri)
{
    Q_ASSERT(uri == QLatin1String("UAdBlock"));

    qmlRegisterType<Cmd>(uri, 1, 0, "Cmd");
}

void BackendPlugin::initializeEngine(QQmlEngine *engine, const char *uri)
{
    QQmlExtensionPlugin::initializeEngine(engine, uri);
}
