#include "clockintents.h"
#include "clockservice.h"

#include <LingmoIntents/intentservice.h>

#include <QDateTime>
#include <cmath>

using LingmoIntents::IntentCall;
using LingmoIntents::IntentResult;

void publishClockIntents(ClockService *service, QObject *parent)
{
    auto *intents = new LingmoIntents::IntentService(QStringLiteral("lingmo-clock"), parent);
    intents->handle(QStringLiteral("clock.alarm.create"), [service](const IntentCall &call) {
        const QString time = call.params().value(QStringLiteral("time")).toString();
        const QString label = call.params().value(QStringLiteral("label")).toString();
        if (!service->addAlarm(time, label))
            return IntentResult::failed(QObject::tr("Hora do alarme inválida (use HH:MM)."));
        return IntentResult::ok({{QStringLiteral("time"), time}, {QStringLiteral("label"), label}});
    });
    intents->handle(QStringLiteral("clock.timer.start"), [service](const IntentCall &call) {
        const int seconds = int(std::lround(call.params().value(QStringLiteral("minutes")).toDouble() * 60));
        const QString label = call.params().value(QStringLiteral("label")).toString();
        if (!service->startTimer(seconds, label))
            return IntentResult::failed(QObject::tr("O timer vai de 1 segundo a 24 horas."));
        return IntentResult::ok({{QStringLiteral("seconds"), seconds},
                                 {QStringLiteral("label"), label},
                                 {QStringLiteral("endsAt"), QDateTime::currentDateTime().addSecs(seconds).toString(QStringLiteral("HH:mm:ss"))}});
    });
    intents->publish();     // /Intents next to /Clock on com.lingmo.Clock
}
