#pragma once

class ClockService;
class QObject;

// Lingmo Intents (com.lingmo.Intents at /Intents on com.lingmo.Clock):
// clock.alarm.create and clock.timer.start, the same work as the older
// addAlarm/startTimer methods, which stay as they are.
void publishClockIntents(ClockService *service, QObject *parent);
