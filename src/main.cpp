#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include "alarmmanager.h"

int main(int argc, char *argv[]) {
    QGuiApplication app(argc, argv);
    QGuiApplication::setOrganizationName("lingmoos");
    QGuiApplication::setApplicationName("lingmo-clock");

    AlarmManager manager;

    QQmlApplicationEngine engine;
    engine.rootContext()->setContextProperty("alarmManager", &manager);
    engine.load(QUrl(QStringLiteral("qrc:/qml/Main.qml")));

    if (engine.rootObjects().isEmpty())
        return -1;

    return app.exec();
}
