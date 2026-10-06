#pragma once
#include <QObject>
#include <QVariantList>
#include <QSqlDatabase>
#include <QTimer>

class AlarmManager : public QObject {
    Q_OBJECT
    Q_PROPERTY(QVariantList alarms READ alarms NOTIFY alarmsChanged)
public:
    explicit AlarmManager(QObject *parent = nullptr);
    ~AlarmManager();
    QVariantList alarms() const;

    Q_INVOKABLE void addAlarm(const QString &time, const QString &label);
    Q_INVOKABLE void toggleAlarm(int id, bool active);
    Q_INVOKABLE void deleteAlarm(int id);

signals:
    void alarmsChanged();
    void alarmRinging(const QString &label);

private slots:
    void checkAlarms();

private:
    void initDb();
    void loadAlarms();
    
    QSqlDatabase m_db;
    QVariantList m_alarms;
    QTimer *m_timer;
};
