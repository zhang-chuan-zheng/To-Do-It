#pragma once

#include <QByteArray>
#include <QString>
#include <QStringList>

namespace todoit::updater {

struct UpdateReport final
{
    bool success{false};
    QString mode;
    QString action;
    QString message;
    QString previousAppVersion;
    QString currentAppVersion;
    QString eventFile;
    QString backupFile;
    int sourceSchema{-1};
    int targetSchema{-1};
    qsizetype eventCount{0};
    QByteArray beforeSha256;
    QByteArray afterSha256;
    QString changeSummary;
    QStringList addedFiles;
    QStringList changedFiles;
    QStringList removedFiles;
};

} // namespace todoit::updater
