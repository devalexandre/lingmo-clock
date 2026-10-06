#include "alarmmanager.h"
#include <QSqlQuery>
#include <QSqlError>
#include <QDateTime>
#include <QStandardPaths>
#include <QDir>
#include <QDebug>

AlarmManager::AlarmManager(QObject *parent) : QObject(parent) {
    initDb();
    loadAlarms();
    
    m_timer = new QTimer(this);
    connect(m_timer, &QTimer::timeout, this, &AlarmManager::checkAlarms);
    m_timer->start(60000); // Check every minute
}

AlarmManager::~AlarmManager() {
    if (m_db.isOpen()) m_db.close();
}

void AlarmManager::initDb() {
    QString dataDir = QStandardPaths::writableLocation(QStandardPaths::AppDataLocation);
    QDir().mkpath(dataDir);
    
    m_db = QSqlDatabase::addDatabase("QSQLITE", "alarms_db");
    m_db.setDatabaseName(dataDir + "/alarms.db");
    
    if (m_db.open()) {
        QSqlQuery query(m_db);
        query.exec("CREATE TABLE IF NOT EXISTS alarms ("
                   "id INTEGER PRIMARY KEY AUTOINCREMENT, "
                   "time_str TEXT, "
                   "label TEXT, "
                   "active INTEGER DEFAULT 1)");
    }
}

QVariantList AlarmManager::alarms() const {
    return m_alarms;
}

void AlarmManager::loadAlarms() {
    m_alarms.clear();
    QSqlQuery query("SELECT id, time_str, label, active FROM alarms ORDER BY time_str ASC", m_db);
    while (query.next()) {
        m_alarms.append(QVariantMap{
            {"id", query.value("id").toInt()},
            {"time", query.value("time_str").toString()},
            {"label", query.value("label").toString()},
            {"active", query.value("active").toInt() == 1}
        });
    }
    emit alarmsChanged();
}

void AlarmManager::addAlarm(const QString &time, const QString &label) {
    QSqlQuery query(m_db);
    query.prepare("INSERT INTO alarms (time_str, label, active) VALUES (:time, :label, 1)");
    query.bindValue(":time", time);
    query.bindValue(":label", label);
    if (query.exec()) {
        loadAlarms();
    }
}

void AlarmManager::toggleAlarm(int id, bool active) {
    QSqlQuery query(m_db);
    query.prepare("UPDATE alarms SET active = :active WHERE id = :id");
    query.bindValue(":active", active ? 1 : 0);
    query.bindValue(":id", id);
    if (query.exec()) {
        loadAlarms();
    }
}

void AlarmManager::deleteAlarm(int id) {
    QSqlQuery query(m_db);
    query.prepare("DELETE FROM alarms WHERE id = :id");
    query.bindValue(":id", id);
    if (query.exec()) {
        loadAlarms();
    }
}

void AlarmManager::checkAlarms() {
    QString currentTime = QTime::currentTime().toString("HH:mm");
    for (const QVariant &v : m_alarms) {
        QVariantMap alarm = v.toMap();
        if (alarm["active"].toBool() && alarm["time"].toString() == currentTime) {
            emit alarmRinging(alarm["label"].toString());
        }
    }
}
