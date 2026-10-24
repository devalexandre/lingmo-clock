#include "clockservice.h"
#include "alarmmanager.h"

#include <QDBusConnection>
#include <QDBusMessage>
#include <QDBusPendingCall>
#include <QRegularExpression>
#include <QTimer>
#include <QVariantMap>

ClockService::ClockService(AlarmManager *alarms, std::function<void()> show, QObject *parent)
    : QObject(parent)
    , m_alarms(alarms)
    , m_show(std::move(show))
{
}

void ClockService::notify(const QString &title, const QString &body)
{
    QDBusMessage msg = QDBusMessage::createMethodCall(QStringLiteral("org.freedesktop.Notifications"),
                                                      QStringLiteral("/org/freedesktop/Notifications"),
                                                      QStringLiteral("org.freedesktop.Notifications"),
                                                      QStringLiteral("Notify"));
    msg << QStringLiteral("lingmo-clock") << uint(0) << QStringLiteral("lingmo-clock") << title << body
        << QStringList() << QVariantMap{{QStringLiteral("desktop-entry"), QStringLiteral("lingmo-clock")},
                                        {QStringLiteral("urgency"), QVariant::fromValue(uchar(2))}}
        << int(-1);
    QDBusConnection::sessionBus().asyncCall(msg);
}

bool ClockService::hasActiveWork() const
{
    if (m_runningTimers > 0)
        return true;
    for (const QVariant &v : m_alarms->alarms())
        if (v.toMap().value(QStringLiteral("active")).toBool())
            return true;
    return false;
}

bool ClockService::addAlarm(const QString &time, const QString &label)
{
    static const QRegularExpression valid(QStringLiteral("^([01]\\d|2[0-3]):[0-5]\\d$"));
    if (!valid.match(time).hasMatch())
        return false;
    const QString name = label.simplified().left(100);
    m_alarms->addAlarm(time, name.isEmpty() ? tr("Alarme") : name);
    return true;
}

bool ClockService::startTimer(int seconds, const QString &label)
{
    if (seconds < 1 || seconds > 24 * 3600)
        return false;
    const QString name = label.simplified().left(100).isEmpty() ? tr("Timer") : label.simplified().left(100);
    ++m_runningTimers;
    QTimer::singleShot(seconds * 1000, this, [this, name] {
        --m_runningTimers;
        Q_EMIT timerFinished(name);
    });
    return true;
}

void ClockService::show()
{
    if (m_show)
        m_show();
}
