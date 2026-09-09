#include "UpdateHistoryWriter.h"

#include <QDateTime>
#include <QDir>
#include <QFile>
#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>

namespace todoit::updater {

bool UpdateHistoryWriter::append(const QString& dataDirectory,
                                 const UpdateReport& report,
                                 QString* error)
{
    const auto logDirectory = QDir(dataDirectory).filePath(QStringLiteral("logs"));
    if (!QDir().mkpath(logDirectory)) {
        if (error != nullptr)
            *error = QStringLiteral("无法创建更新日志目录：%1").arg(logDirectory);
        return false;
    }

    const auto historyFile = QDir(logDirectory).filePath(
        QStringLiteral("update-history.jsonl"));
    QFile file(historyFile);
    if (!file.open(QIODevice::WriteOnly | QIODevice::Append)) {
        if (error != nullptr)
            *error = QStringLiteral("无法写入更新历史：%1").arg(historyFile);
        return false;
    }

    QJsonObject entry{
        {QStringLiteral("timestampUtc"),
         QDateTime::currentDateTimeUtc().toString(Qt::ISODateWithMs)},
        {QStringLiteral("success"), report.success},
        {QStringLiteral("mode"), report.mode},
        {QStringLiteral("action"), report.action},
        {QStringLiteral("message"), report.message},
        {QStringLiteral("previousAppVersion"), report.previousAppVersion},
        {QStringLiteral("currentAppVersion"), report.currentAppVersion},
        {QStringLiteral("sourceEventSchema"), report.sourceSchema},
        {QStringLiteral("targetEventSchema"), report.targetSchema},
        {QStringLiteral("eventCount"), static_cast<qint64>(report.eventCount)},
        {QStringLiteral("eventFile"), report.eventFile},
        {QStringLiteral("backupFile"), report.backupFile},
        {QStringLiteral("beforeSha256"), QString::fromLatin1(report.beforeSha256)},
        {QStringLiteral("afterSha256"), QString::fromLatin1(report.afterSha256)}};

    QJsonArray added;
    for (const auto& item : report.addedFiles)
        added.append(item);
    QJsonArray changed;
    for (const auto& item : report.changedFiles)
        changed.append(item);
    QJsonArray removed;
    for (const auto& item : report.removedFiles)
        removed.append(item);
    entry.insert(QStringLiteral("changeSummary"), report.changeSummary);
    entry.insert(QStringLiteral("programFilesAdded"), added);
    entry.insert(QStringLiteral("programFilesChanged"), changed);
    entry.insert(QStringLiteral("programFilesRemoved"), removed);

    const auto line = QJsonDocument(entry).toJson(QJsonDocument::Compact) + '\n';
    if (file.write(line) != line.size() || !file.flush()) {
        if (error != nullptr)
            *error = QStringLiteral("更新历史没有完整写入：%1").arg(historyFile);
        return false;
    }
    return true;
}

} // namespace todoit::updater
