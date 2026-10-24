#include <QDBusConnection>
#include <QDBusInterface>
#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QQuickWindow>
#include "alarmmanager.h"
#include "clockservice.h"

static const QString DBusService = QStringLiteral("com.lingmo.Clock");
static const QString DBusPath = QStringLiteral("/Clock");

int main(int argc, char *argv[]) {
    QGuiApplication app(argc, argv);
    QGuiApplication::setOrganizationName("lingmoos");
    QGuiApplication::setApplicationName("lingmo-clock");
    QGuiApplication::setDesktopFileName("lingmo-clock");

    const QStringList arguments = app.arguments();
    // --background: no window, alarms and timers ring as notifications (D-Bus
    // activation and the session autostart use it); --add-alarm HH:MM [label]
    const bool background = arguments.contains(QStringLiteral("--background"));
    const int addAlarmArg = arguments.indexOf(QStringLiteral("--add-alarm"));

    // One clock per session: a second launch hands its request over
    QDBusConnection bus = QDBusConnection::sessionBus();
    if (bus.isConnected() && !bus.registerService(DBusService)) {
        QDBusInterface iface(DBusService, DBusPath, DBusService, bus);
        const int timer = arguments.indexOf(QStringLiteral("--timer"));
        if (addAlarmArg >= 0 && addAlarmArg + 1 < arguments.size())
            iface.call(QStringLiteral("addAlarm"), arguments.at(addAlarmArg + 1), arguments.value(addAlarmArg + 2));
        else if (timer >= 0 && timer + 1 < arguments.size())
            iface.call(QStringLiteral("startTimer"), arguments.at(timer + 1).toInt(), QString());
        if (!background && addAlarmArg < 0)
            iface.call(QStringLiteral("show"));
        return 0;
    }

    AlarmManager manager;

    // --timer SECONDS starts a countdown right away (also handy for scripts)
    int timerSeconds = 0;
    const QStringList args = app.arguments();
    const int timerArg = args.indexOf(QStringLiteral("--timer"));
    if (timerArg >= 0 && timerArg + 1 < args.size())
        timerSeconds = qMax(0, args.at(timerArg + 1).toInt());

    QQmlApplicationEngine engine;
    engine.rootContext()->setContextProperty("alarmManager", &manager);
    engine.rootContext()->setContextProperty("initialTimerSeconds", timerSeconds);
    auto showWindow = [&engine] {
        if (engine.rootObjects().isEmpty())
            engine.load(QUrl(QStringLiteral("qrc:/qml/Main.qml")));
        if (auto *window = qobject_cast<QQuickWindow *>(engine.rootObjects().value(0))) {
            window->show();
            window->raise();
            window->requestActivate();
        }
    };

    ClockService service(&manager, showWindow);
    if (bus.isConnected())
        bus.registerObject(DBusPath, &service, QDBusConnection::ExportAllSlots);
    if (addAlarmArg >= 0 && addAlarmArg + 1 < arguments.size())
        service.addAlarm(arguments.at(addAlarmArg + 1), arguments.value(addAlarmArg + 2));

    // Without a window open, alarms and timers ring as notifications
    auto windowVisible = [&engine] {
        auto *window = qobject_cast<QQuickWindow *>(engine.rootObjects().value(0));
        return window && window->isVisible();
    };
    QObject::connect(&manager, &AlarmManager::alarmRinging, &app, [windowVisible](const QString &label) {
        if (!windowVisible())
            ClockService::notify(QObject::tr("Alarme"), label);
    });
    QObject::connect(&service, &ClockService::timerFinished, &app, [windowVisible, &manager](const QString &label) {
        if (windowVisible())
            Q_EMIT manager.alarmRinging(label);      // the window's ringing dialog
        else
            ClockService::notify(QObject::tr("Timer concluído"), label);
    });

    // Closing the window keeps the clock running while alarms or timers are active
    app.setQuitOnLastWindowClosed(false);
    QObject::connect(&app, &QGuiApplication::lastWindowClosed, &app, [&service] {
        if (!service.hasActiveWork())
            QGuiApplication::quit();
    });

    if (!background && addAlarmArg < 0) {
        showWindow();
        if (engine.rootObjects().isEmpty())
            return -1;
    }

    return app.exec();
}
