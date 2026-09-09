#include "UpdateCoordinator.h"

#include "EventCsvMigrator.h"
#include "UpdateHistoryWriter.h"
#include "UpdateManifest.h"
#include "infrastructure/persistence/CsvCodec.h"
#include "infrastructure/persistence/CsvEventRepository.h"

#include <QCryptographicHash>
#include <QDateTime>
#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QJsonDocument>
#include <QJsonObject>
#include <QLockFile>
#include <QSaveFile>
#include <QTemporaryFile>
#include <QUuid>

#include <algorithm>
#include <filesystem>
#include <fstream>
#include <optional>
#include <string>
#include <vector>
#include <utility>

namespace todoit::updater {
namespace {

struct Inspection final
{
    int schema{-1};
    qsizetype eventCount{0};
    QByteArray sha256;
    QString error;
};

[[nodiscard]] std::filesystem::path nativePath(const QString& path)
{
    return std::filesystem::path(path.toStdWString());
}

[[nodiscard]] QByteArray fileSha256(const QString& path, QString* error)
{
    QFile file(path);
    if (!file.open(QIODevice::ReadOnly)) {
        if (error != nullptr)
            *error = QStringLiteral("无法读取文件以计算校验值：%1").arg(path);
        return {};
    }

    QCryptographicHash hash(QCryptographicHash::Sha256);
    if (!hash.addData(&file)) {
        if (error != nullptr)
            *error = QStringLiteral("无法计算文件校验值：%1").arg(path);
        return {};
    }
    return hash.result().toHex();
}

[[nodiscard]] std::vector<std::string> schemaHeader(
    const EventSchemaDescriptor& schema)
{
    std::vector<std::string> header;
    header.reserve(static_cast<std::size_t>(schema.columns.size()));
    for (const auto& column : schema.columns)
        header.push_back(column.name.toUtf8().toStdString());
    return header;
}

[[nodiscard]] Inspection inspectEventFile(const QString& path,
                                          const UpdateManifest& manifest)
{
    Inspection inspection;
    std::ifstream input(nativePath(path), std::ios::binary);
    if (!input) {
        inspection.error = QStringLiteral("无法打开 event.csv：%1").arg(path);
        return inspection;
    }

    const auto parsed = infrastructure::CsvCodec::parse(input);
    if (parsed.error.has_value()) {
        inspection.error = QStringLiteral("event.csv 第 %1 行解析失败：%2")
                               .arg(static_cast<qulonglong>(parsed.error->line))
                               .arg(QString::fromStdString(parsed.error->message));
        return inspection;
    }
    if (parsed.records.empty()) {
        inspection.error = QStringLiteral("event.csv 缺少表头");
        return inspection;
    }

    const auto& header = parsed.records.front().fields;
    if (header.empty() || header.front() != "schema_version") {
        inspection.error = QStringLiteral(
            "event.csv 没有 schema_version，无法在不猜测字段含义的情况下迁移");
        return inspection;
    }

    std::optional<int> detectedVersion;
    for (std::size_t index = 1; index < parsed.records.size(); ++index) {
        const auto& row = parsed.records[index];
        if (row.fields.empty())
            continue;
        bool ok = false;
        const auto version = QString::fromStdString(row.fields.front()).toInt(&ok);
        if (!ok || version < 1) {
            inspection.error = QStringLiteral("event.csv 第 %1 行架构号无效")
                                   .arg(static_cast<qulonglong>(row.line));
            return inspection;
        }
        if (detectedVersion.has_value() && *detectedVersion != version) {
            inspection.error = QStringLiteral("event.csv 同时包含多个架构版本");
            return inspection;
        }
        detectedVersion = version;
    }

    if (!detectedVersion.has_value()) {
        for (const auto& schema : manifest.eventSchemas) {
            if (header == schemaHeader(schema)) {
                if (detectedVersion.has_value()) {
                    inspection.error = QStringLiteral(
                        "空 event.csv 的表头同时匹配多个架构，无法安全迁移");
                    return inspection;
                }
                detectedVersion = schema.version;
            }
        }
        if (!detectedVersion.has_value()) {
            inspection.error = QStringLiteral(
                "空 event.csv 的表头不属于任何已登记架构，无法安全推断版本");
            return inspection;
        }
    }

    const auto* sourceSchema = manifest.schema(*detectedVersion);
    if (sourceSchema == nullptr) {
        inspection.error = QStringLiteral("发布清单没有登记 event schema %1 的字段结构")
                               .arg(*detectedVersion);
        return inspection;
    }
    if (header != schemaHeader(*sourceSchema)) {
        inspection.error = QStringLiteral(
            "event.csv 表头与已登记的 schema %1 不一致，已拒绝猜测字段")
                               .arg(*detectedVersion);
        return inspection;
    }

    inspection.schema = *detectedVersion;
    inspection.eventCount = static_cast<qsizetype>(parsed.records.size() - 1);
    inspection.sha256 = fileSha256(path, &inspection.error);
    return inspection;
}

[[nodiscard]] std::optional<infrastructure::CsvParseResult> parseEventFile(
    const QString& path, QString* error)
{
    std::ifstream input(nativePath(path), std::ios::binary);
    if (!input) {
        if (error != nullptr)
            *error = QStringLiteral("无法打开 event.csv：%1").arg(path);
        return std::nullopt;
    }
    auto parsed = infrastructure::CsvCodec::parse(input);
    if (parsed.error.has_value()) {
        if (error != nullptr) {
            *error = QStringLiteral("event.csv 第 %1 行解析失败：%2")
                         .arg(static_cast<qulonglong>(parsed.error->line))
                         .arg(QString::fromStdString(parsed.error->message));
        }
        return std::nullopt;
    }
    return parsed;
}

[[nodiscard]] bool migrateEventFile(const QString& eventFile,
                                    const EventSchemaDescriptor& targetSchema,
                                    qsizetype* eventCount,
                                    QString* error)
{
    auto parsed = parseEventFile(eventFile, error);
    if (!parsed.has_value())
        return false;

    const auto migration = EventCsvMigrator::migrate(*parsed, targetSchema);
    if (!migration.success) {
        if (error != nullptr)
            *error = migration.error;
        return false;
    }

    QTemporaryFile candidate(
        QFileInfo(eventFile).dir().filePath(QStringLiteral(".event-migration-XXXXXX.csv")));
    candidate.setAutoRemove(true);
    if (!candidate.open()
        || candidate.write(migration.content) != migration.content.size()
        || !candidate.flush()) {
        if (error != nullptr)
            *error = QStringLiteral("无法写入迁移候选文件；原 event.csv 未修改");
        return false;
    }
    candidate.close();

    const infrastructure::CsvEventRepository candidateRepository(
        nativePath(candidate.fileName()));
    const auto validation = candidateRepository.load();
    if (!validation.succeeded()) {
        const auto& loadError = *validation.error;
        if (error != nullptr) {
            *error = QStringLiteral("迁移结果校验失败（第 %1 行）：%2；原 event.csv 未修改")
                         .arg(static_cast<qulonglong>(loadError.line))
                         .arg(QString::fromStdString(loadError.message));
        }
        return false;
    }

    QSaveFile output(eventFile);
    output.setDirectWriteFallback(false);
    if (!output.open(QIODevice::WriteOnly)
        || output.write(migration.content) != migration.content.size()
        || !output.commit()) {
        if (error != nullptr)
            *error = QStringLiteral("迁移结果无法原子保存；原 event.csv 未修改");
        return false;
    }
    if (eventCount != nullptr)
        *eventCount = migration.eventCount;
    return true;
}

[[nodiscard]] QString readPreviousVersion(const QString& dataDirectory)
{
    QFile file(QDir(dataDirectory).filePath(
        QStringLiteral("config/install-state.json")));
    if (!file.open(QIODevice::ReadOnly))
        return {};
    const auto document = QJsonDocument::fromJson(file.readAll());
    return document.object().value(QStringLiteral("appVersion")).toString();
}

[[nodiscard]] bool writeInstallState(const QString& dataDirectory,
                                     const UpdateReport& report,
                                     QString* error)
{
    const auto configDirectory = QDir(dataDirectory).filePath(
        QStringLiteral("config"));
    if (!QDir().mkpath(configDirectory)) {
        if (error != nullptr)
            *error = QStringLiteral("无法创建安装状态目录：%1").arg(configDirectory);
        return false;
    }

    const auto statePath = QDir(configDirectory).filePath(
        QStringLiteral("install-state.json"));
    QSaveFile file(statePath);
    file.setDirectWriteFallback(false);
    if (!file.open(QIODevice::WriteOnly)) {
        if (error != nullptr)
            *error = QStringLiteral("无法写入安装状态：%1").arg(statePath);
        return false;
    }

    const QJsonObject state{
        {QStringLiteral("appVersion"), report.currentAppVersion},
        {QStringLiteral("eventSchema"), report.targetSchema},
        {QStringLiteral("updatedAtUtc"),
         QDateTime::currentDateTimeUtc().toString(Qt::ISODateWithMs)}};
    const auto content = QJsonDocument(state).toJson(QJsonDocument::Indented);
    if (file.write(content) != content.size() || !file.commit()) {
        if (error != nullptr)
            *error = QStringLiteral("安装状态没有原子提交：%1").arg(statePath);
        return false;
    }
    return true;
}

[[nodiscard]] QString createBackup(const QString& dataDirectory,
                                   const QString& eventFile,
                                   const int sourceSchema,
                                   const int targetSchema,
                                   QString* error)
{
    const auto backupDirectory = QDir(dataDirectory).filePath(
        QStringLiteral("backups/migrations"));
    if (!QDir().mkpath(backupDirectory)) {
        if (error != nullptr)
            *error = QStringLiteral("无法创建迁移备份目录：%1").arg(backupDirectory);
        return {};
    }

    const auto timestamp = QDateTime::currentDateTimeUtc().toString(
        QStringLiteral("yyyyMMdd-HHmmss-zzz"));
    const auto suffix = QUuid::createUuid().toString(QUuid::WithoutBraces).left(8);
    const auto backupFile = QDir(backupDirectory).filePath(
        QStringLiteral("event-v%1-to-v%2-%3-%4.csv")
            .arg(sourceSchema)
            .arg(targetSchema)
            .arg(timestamp, suffix));
    if (!QFile::copy(eventFile, backupFile)) {
        if (error != nullptr)
            *error = QStringLiteral("无法创建迁移前备份：%1").arg(backupFile);
        return {};
    }
    return backupFile;
}

[[nodiscard]] bool restoreBackup(const QString& backupFile,
                                 const QString& eventFile,
                                 QString* error)
{
    QFile source(backupFile);
    if (!source.open(QIODevice::ReadOnly)) {
        if (error != nullptr)
            *error = QStringLiteral("无法读取迁移备份：%1").arg(backupFile);
        return false;
    }
    const auto content = source.readAll();
    QSaveFile output(eventFile);
    output.setDirectWriteFallback(false);
    if (!output.open(QIODevice::WriteOnly)
        || output.write(content) != content.size()
        || !output.commit()) {
        if (error != nullptr)
            *error = QStringLiteral("迁移后续步骤失败，且无法恢复备份：%1")
                         .arg(backupFile);
        return false;
    }
    return true;
}

[[nodiscard]] bool hasDeclaredContiguousPath(const UpdateManifest& manifest,
                                             int sourceSchema)
{
    while (sourceSchema < manifest.eventSchema) {
        const auto found = std::find_if(
            manifest.eventMigrations.cbegin(), manifest.eventMigrations.cend(),
            [sourceSchema](const MigrationDescriptor& item) {
                return item.fromSchema == sourceSchema
                    && item.toSchema == sourceSchema + 1;
            });
        if (found == manifest.eventMigrations.cend())
            return false;
        sourceSchema = found->toSchema;
    }
    return sourceSchema == manifest.eventSchema;
}

[[nodiscard]] UpdateReport failureReport(UpdateReport report, QString message)
{
    report.success = false;
    report.action = QStringLiteral("blocked");
    report.message = std::move(message);
    return report;
}

} // namespace

UpdateReport UpdateCoordinator::execute(const UpdateOptions& options) const
{
    UpdateReport report;
    report.mode = options.mode;
    report.eventFile = QDir(options.dataDirectory).filePath(QStringLiteral("event.csv"));
    report.previousAppVersion = readPreviousVersion(options.dataDirectory);

    QString error;
    const auto manifest = UpdateManifest::load(options.manifestFile, &error);
    if (!manifest.has_value())
        return failureReport(std::move(report), error);

    report.currentAppVersion = manifest->appVersion;
    report.targetSchema = manifest->eventSchema;
    report.changeSummary = manifest->changeSummary;
    report.addedFiles = manifest->addedFiles;
    report.changedFiles = manifest->changedFiles;
    report.removedFiles = manifest->removedFiles;
    if (manifest->eventSchema
        != infrastructure::CsvEventRepository::supportedSchemaVersion) {
        return failureReport(
            std::move(report),
            QStringLiteral("迁移器只实现 event schema %1，但发布清单要求 %2；已阻止更新")
                .arg(infrastructure::CsvEventRepository::supportedSchemaVersion)
                .arg(manifest->eventSchema));
    }

    if (!QDir().mkpath(options.dataDirectory)) {
        return failureReport(std::move(report),
                             QStringLiteral("无法创建数据目录：%1")
                                 .arg(options.dataDirectory));
    }

    QLockFile lock(QDir(options.dataDirectory).filePath(
        QStringLiteral(".migration.lock")));
    lock.setStaleLockTime(30'000);
    if (!lock.tryLock(0)) {
        return failureReport(std::move(report),
                             QStringLiteral("数据目录正在被另一个更新进程使用"));
    }

    if (!QFileInfo::exists(report.eventFile)) {
        report.sourceSchema = report.targetSchema;
        report.success = true;
        report.action = QStringLiteral("initialized");
        report.message = QStringLiteral("尚无 event.csv；保留给应用首次启动创建");
    } else {
        const auto inspection = inspectEventFile(report.eventFile, *manifest);
        report.sourceSchema = inspection.schema;
        report.eventCount = inspection.eventCount;
        report.beforeSha256 = inspection.sha256;
        if (!inspection.error.isEmpty())
            return failureReport(std::move(report), inspection.error);
        if (inspection.schema > manifest->eventSchema) {
            return failureReport(
                std::move(report),
                QStringLiteral("event.csv 架构 %1 新于安装包架构 %2，禁止降级覆盖")
                    .arg(inspection.schema)
                    .arg(manifest->eventSchema));
        }

        report.backupFile = createBackup(options.dataDirectory, report.eventFile,
                                         inspection.schema,
                                         manifest->eventSchema, &error);
        if (report.backupFile.isEmpty())
            return failureReport(std::move(report), error);
        const auto backupSha256 = fileSha256(report.backupFile, &error);
        if (backupSha256.isEmpty() && !error.isEmpty())
            return failureReport(std::move(report), error);
        if (backupSha256 != report.beforeSha256) {
            return failureReport(std::move(report),
                                 QStringLiteral("迁移备份校验值与原文件不一致；原文件未修改"));
        }

        if (inspection.schema < manifest->eventSchema) {
            if (!hasDeclaredContiguousPath(*manifest, inspection.schema)) {
                return failureReport(
                    std::move(report),
                    QStringLiteral("没有从 event schema %1 到 %2 的连续迁移声明；原文件未修改")
                        .arg(inspection.schema)
                        .arg(manifest->eventSchema));
            }

            const auto* targetSchema = manifest->schema(manifest->eventSchema);
            if (targetSchema == nullptr) {
                return failureReport(
                    std::move(report),
                    QStringLiteral("发布清单缺少目标字段结构；原文件未修改"));
            }
            if (!migrateEventFile(report.eventFile, *targetSchema,
                                  &report.eventCount, &error)) {
                return failureReport(std::move(report), error);
            }

            report.afterSha256 = fileSha256(report.eventFile, &error);
            if (report.afterSha256.isEmpty() && !error.isEmpty()) {
                QString restoreError;
                if (!restoreBackup(report.backupFile, report.eventFile,
                                   &restoreError)) {
                    error += QStringLiteral("；%1").arg(restoreError);
                } else {
                    error += QStringLiteral("；event.csv 已恢复到迁移前版本");
                }
                return failureReport(std::move(report), error);
            }
            report.success = true;
            report.action = QStringLiteral("migrated");
            report.message = QStringLiteral(
                "event.csv 已按稳定字段名从 schema %1 迁移到 %2；新增字段使用清单缺省值，已删除字段不再写入")
                                 .arg(inspection.schema)
                                 .arg(manifest->eventSchema);
        } else {
            const infrastructure::CsvEventRepository repository(
                nativePath(report.eventFile));
            const auto validation = repository.load();
            if (!validation.succeeded()) {
                const auto& loadError = *validation.error;
                return failureReport(
                    std::move(report),
                    QStringLiteral("event.csv 当前架构校验失败（第 %1 行）：%2；原文件未修改")
                        .arg(static_cast<qulonglong>(loadError.line))
                        .arg(QString::fromStdString(loadError.message)));
            }

            report.afterSha256 = fileSha256(report.eventFile, &error);
            if (report.afterSha256.isEmpty() && !error.isEmpty())
                return failureReport(std::move(report), error);
            if (report.beforeSha256 != report.afterSha256) {
                return failureReport(std::move(report),
                                     QStringLiteral("只读校验期间数据意外变化；已阻止更新"));
            }

            report.success = true;
            report.action = QStringLiteral("validated");
            report.message = QStringLiteral("event.csv 架构一致并已完成迁移前备份与完整校验");
        }
    }

    if (!writeInstallState(options.dataDirectory, report, &error)) {
        if (report.action == QStringLiteral("migrated")) {
            QString restoreError;
            if (!restoreBackup(report.backupFile, report.eventFile, &restoreError))
                error += QStringLiteral("；%1").arg(restoreError);
            else
                error += QStringLiteral("；event.csv 已恢复到迁移前版本");
        }
        return failureReport(std::move(report), error);
    }
    if (!UpdateHistoryWriter::append(options.dataDirectory, report, &error)) {
        report.message += QStringLiteral("；警告：%1").arg(error);
    }
    return report;
}

} // namespace todoit::updater
