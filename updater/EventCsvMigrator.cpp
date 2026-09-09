#include "EventCsvMigrator.h"

#include <QHash>

#include <string>
#include <string_view>
#include <utility>
#include <vector>

namespace todoit::updater {
namespace {

[[nodiscard]] std::string encodeCsvField(const std::string_view value)
{
    if (value.find_first_of(",\"\r\n") == std::string_view::npos)
        return std::string(value);

    std::string encoded;
    encoded.reserve(value.size() + 2);
    encoded.push_back('"');
    for (const auto character : value) {
        if (character == '"')
            encoded.push_back('"');
        encoded.push_back(character);
    }
    encoded.push_back('"');
    return encoded;
}

void appendRow(QByteArray& output, const std::vector<std::string>& fields)
{
    for (std::size_t index = 0; index < fields.size(); ++index) {
        if (index > 0)
            output.push_back(',');
        const auto encoded = encodeCsvField(fields[index]);
        output.append(encoded.data(), static_cast<qsizetype>(encoded.size()));
    }
    output.append("\r\n");
}

[[nodiscard]] EventCsvMigrationResult failure(QString error)
{
    EventCsvMigrationResult result;
    result.error = std::move(error);
    return result;
}

} // namespace

EventCsvMigrationResult EventCsvMigrator::migrate(
    const infrastructure::CsvParseResult& source,
    const EventSchemaDescriptor& targetSchema)
{
    if (source.error.has_value()) {
        return failure(QStringLiteral("源 event.csv 解析失败：%1")
                           .arg(QString::fromStdString(source.error->message)));
    }
    if (source.records.empty())
        return failure(QStringLiteral("源 event.csv 缺少表头"));
    if (targetSchema.version < 1 || targetSchema.columns.isEmpty())
        return failure(QStringLiteral("目标 event schema 定义无效"));

    const auto& sourceHeader = source.records.front().fields;
    QHash<QString, std::size_t> sourceIndices;
    sourceIndices.reserve(static_cast<qsizetype>(sourceHeader.size()));
    for (std::size_t index = 0; index < sourceHeader.size(); ++index) {
        const auto name = QString::fromUtf8(sourceHeader[index]);
        if (name.isEmpty() || sourceIndices.contains(name)) {
            return failure(QStringLiteral("源 event.csv 表头包含空白或重复字段：%1")
                               .arg(name));
        }
        sourceIndices.insert(name, index);
    }

    std::vector<std::string> targetHeader;
    targetHeader.reserve(static_cast<std::size_t>(targetSchema.columns.size()));
    for (const auto& column : targetSchema.columns)
        targetHeader.push_back(column.name.toUtf8().toStdString());

    QByteArray output("\xEF\xBB\xBF", 3);
    appendRow(output, targetHeader);

    for (std::size_t rowIndex = 1; rowIndex < source.records.size(); ++rowIndex) {
        const auto& record = source.records[rowIndex];
        if (record.fields.size() != sourceHeader.size()) {
            return failure(QStringLiteral(
                "源 event.csv 第 %1 行字段数与表头不一致")
                               .arg(static_cast<qulonglong>(record.line)));
        }

        std::vector<std::string> migrated;
        migrated.reserve(static_cast<std::size_t>(targetSchema.columns.size()));
        for (const auto& column : targetSchema.columns) {
            if (column.name == QStringLiteral("schema_version")) {
                migrated.push_back(std::to_string(targetSchema.version));
                continue;
            }
            const auto found = sourceIndices.constFind(column.name);
            if (found == sourceIndices.cend()) {
                migrated.push_back(column.defaultValue.toUtf8().toStdString());
            } else {
                migrated.push_back(record.fields[*found]);
            }
        }
        appendRow(output, migrated);
    }

    EventCsvMigrationResult result;
    result.success = true;
    result.content = std::move(output);
    result.eventCount = static_cast<qsizetype>(source.records.size() - 1);
    return result;
}

} // namespace todoit::updater
