#include "UpdateManifest.h"

#include <QFile>
#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonParseError>
#include <QSet>

#include <algorithm>
#include <utility>

namespace todoit::updater {
namespace {

void setError(QString* error, QString message)
{
    if (error != nullptr)
        *error = std::move(message);
}

[[nodiscard]] QStringList stringArray(const QJsonValue& value)
{
    QStringList result;
    for (const auto& item : value.toArray()) {
        const auto text = item.toString().trimmed();
        if (!text.isEmpty())
            result.push_back(text);
    }
    return result;
}

} // namespace

std::optional<UpdateManifest> UpdateManifest::load(const QString& filePath,
                                                   QString* error)
{
    QFile file(filePath);
    if (!file.open(QIODevice::ReadOnly)) {
        setError(error, QStringLiteral("无法读取发布清单：%1").arg(filePath));
        return std::nullopt;
    }

    QJsonParseError parseError;
    const auto document = QJsonDocument::fromJson(file.readAll(), &parseError);
    if (parseError.error != QJsonParseError::NoError || !document.isObject()) {
        setError(error, QStringLiteral("发布清单不是有效 JSON：%1")
                            .arg(parseError.errorString()));
        return std::nullopt;
    }

    const auto root = document.object();
    UpdateManifest manifest;
    manifest.appVersion = root.value(QStringLiteral("appVersion")).toString().trimmed();
    manifest.eventSchema = root.value(QStringLiteral("eventSchema")).toInt(-1);
    manifest.settingsSchema = root.value(QStringLiteral("settingsSchema")).toInt(-1);
    const auto changes = root.value(QStringLiteral("programChanges")).toObject();
    manifest.changeSummary = changes.value(QStringLiteral("summary")).toString();
    manifest.addedFiles = stringArray(changes.value(QStringLiteral("added")));
    manifest.changedFiles = stringArray(changes.value(QStringLiteral("changed")));
    manifest.removedFiles = stringArray(changes.value(QStringLiteral("removed")));

    if (manifest.appVersion.isEmpty() || manifest.eventSchema < 1
        || manifest.settingsSchema < 1) {
        setError(error, QStringLiteral("发布清单缺少有效的版本或架构号"));
        return std::nullopt;
    }

    QSet<int> schemaVersions;
    const auto schemas = root.value(QStringLiteral("eventSchemas")).toArray();
    manifest.eventSchemas.reserve(schemas.size());
    for (const auto& value : schemas) {
        if (!value.isObject()) {
            setError(error, QStringLiteral("eventSchemas 中存在非对象项目"));
            return std::nullopt;
        }

        const auto object = value.toObject();
        EventSchemaDescriptor schema;
        schema.version = object.value(QStringLiteral("version")).toInt(-1);
        if (schema.version < 1 || schemaVersions.contains(schema.version)) {
            setError(error, QStringLiteral("eventSchemas 包含无效或重复的架构版本"));
            return std::nullopt;
        }

        QSet<QString> columnNames;
        const auto columns = object.value(QStringLiteral("columns")).toArray();
        schema.columns.reserve(columns.size());
        for (const auto& columnValue : columns) {
            if (!columnValue.isObject()) {
                setError(error, QStringLiteral("eventSchemas.columns 中存在非对象项目"));
                return std::nullopt;
            }
            const auto columnObject = columnValue.toObject();
            if (!columnObject.value(QStringLiteral("name")).isString()
                || !columnObject.contains(QStringLiteral("default"))
                || !columnObject.value(QStringLiteral("default")).isString()) {
                setError(error, QStringLiteral(
                    "eventSchemas.columns 的 name 和 default 必须是字符串"));
                return std::nullopt;
            }
            EventColumnDescriptor column{
                columnObject.value(QStringLiteral("name")).toString().trimmed(),
                columnObject.value(QStringLiteral("default")).toString()};
            if (column.name.isEmpty() || columnNames.contains(column.name)) {
                setError(error, QStringLiteral("eventSchemas 包含空白或重复字段名"));
                return std::nullopt;
            }
            columnNames.insert(column.name);
            schema.columns.push_back(std::move(column));
        }
        if (schema.columns.isEmpty()
            || schema.columns.front().name != QStringLiteral("schema_version")) {
            setError(error, QStringLiteral(
                "每个 event schema 的首字段必须是 schema_version"));
            return std::nullopt;
        }
        schemaVersions.insert(schema.version);
        manifest.eventSchemas.push_back(std::move(schema));
    }
    if (manifest.schema(manifest.eventSchema) == nullptr) {
        setError(error, QStringLiteral("eventSchemas 缺少当前 eventSchema 的字段定义"));
        return std::nullopt;
    }

    QSet<QString> migrationIds;
    QSet<int> migrationSources;
    const auto migrations = root.value(QStringLiteral("eventMigrations")).toArray();
    manifest.eventMigrations.reserve(migrations.size());
    for (const auto& value : migrations) {
        if (!value.isObject()) {
            setError(error, QStringLiteral("eventMigrations 中存在非对象项目"));
            return std::nullopt;
        }

        const auto object = value.toObject();
        MigrationDescriptor descriptor{
            object.value(QStringLiteral("id")).toString().trimmed(),
            object.value(QStringLiteral("fromSchema")).toInt(-1),
            object.value(QStringLiteral("toSchema")).toInt(-1),
            stringArray(object.value(QStringLiteral("removedFields")))};
        if (descriptor.id.isEmpty() || descriptor.fromSchema < 1
            || descriptor.toSchema != descriptor.fromSchema + 1
            || migrationIds.contains(descriptor.id)
            || migrationSources.contains(descriptor.fromSchema)) {
            setError(error, QStringLiteral("eventMigrations 包含无效或重复的迁移步骤"));
            return std::nullopt;
        }
        migrationIds.insert(descriptor.id);
        migrationSources.insert(descriptor.fromSchema);
        manifest.eventMigrations.push_back(std::move(descriptor));
    }

    for (const auto& migration : manifest.eventMigrations) {
        const auto* sourceSchema = manifest.schema(migration.fromSchema);
        const auto* targetSchema = manifest.schema(migration.toSchema);
        if (sourceSchema == nullptr || targetSchema == nullptr) {
            setError(error, QStringLiteral(
                "迁移步骤 %1 引用了未登记的 event schema")
                                .arg(migration.id));
            return std::nullopt;
        }

        QSet<QString> sourceFields;
        QSet<QString> targetFields;
        for (const auto& column : sourceSchema->columns)
            sourceFields.insert(column.name);
        for (const auto& column : targetSchema->columns)
            targetFields.insert(column.name);

        QSet<QString> declaredRemoved;
        for (const auto& field : migration.removedFields)
            declaredRemoved.insert(field);
        if (declaredRemoved.size() != migration.removedFields.size()) {
            setError(error, QStringLiteral("迁移步骤 %1 重复声明了删除字段")
                                .arg(migration.id));
            return std::nullopt;
        }
        for (const auto& field : declaredRemoved) {
            if (field == QStringLiteral("schema_version")
                || !sourceFields.contains(field) || targetFields.contains(field)) {
                setError(error, QStringLiteral(
                    "迁移步骤 %1 的 removedFields 包含无效字段：%2")
                                    .arg(migration.id, field));
                return std::nullopt;
            }
        }
        for (const auto& field : sourceFields) {
            if (!targetFields.contains(field) && !declaredRemoved.contains(field)) {
                setError(error, QStringLiteral(
                    "迁移步骤 %1 从 schema %2 删除了字段 %3，"
                    "但未在 removedFields 中显式确认；可能发生了字段重命名")
                                    .arg(migration.id)
                                    .arg(migration.fromSchema)
                                    .arg(field));
                return std::nullopt;
            }
        }
    }

    return manifest;
}

const EventSchemaDescriptor* UpdateManifest::schema(const int version) const noexcept
{
    const auto found = std::find_if(
        eventSchemas.cbegin(), eventSchemas.cend(),
        [version](const EventSchemaDescriptor& descriptor) {
            return descriptor.version == version;
        });
    return found == eventSchemas.cend() ? nullptr : &*found;
}

} // namespace todoit::updater
