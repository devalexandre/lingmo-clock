#pragma once

#include <QObject>
#include <functional>

class AlarmManager;

// com.lingmo.Clock /Clock: lets other apps (Lingmo Assistant's workflows and
// chat tools) create alarms and timers without touching the clock's window.
// It can only add alarms and start timers: nothing is removed or changed.
class ClockService : public QObject
{
    Q_OBJECT
    Q_CLASSINFO("D-Bus Interface", "com.lingmo.Clock")

public:
    ClockService(AlarmManager *alarms, std::function<void()> show, QObject *parent = nullptr);
    // Shows a desktop notification (alarms and timers ringing while no window is open)
    static void notify(const QString &title, const QString &body);
    bool hasActiveWork() const;

Q_SIGNALS:
    void timerFinished(const QString &label);

public Q_SLOTS:
    // time is "HH:MM" (24 h); returns false for an invalid time
    bool addAlarm(const QString &time, const QString &label);
    // 1 s to 24 h; rings with a notification (and the window's dialog when it is open)
    bool startTimer(int seconds, const QString &label);
    void show();

private:
    AlarmManager *m_alarms;
    std::function<void()> m_show;
    int m_runningTimers = 0;
};
