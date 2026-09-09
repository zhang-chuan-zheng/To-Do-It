#include "infrastructure/persistence/CsvEventRepository.h"

#include "infrastructure/persistence/CsvCodec.h"

#include <QByteArray>
#include <QDateTime>
#include <QDir>
#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonParseError>
#include <QRegularExpression>
#include <QSaveFile>
#include <QStringConverter>
#include <QUuid>

#include <array>
#include <charconv>
#include <cmath>
#include <fstream>
#include <limits>
#include <optional>
#include <string_view>
#include <system_error>
#include <unordered_map>
#include <unordered_set>
#include <utility>

namespace todoit::infrastructure {
namespace {

constexpr std::size_t expectedColumnCount = 13;

constexpr char initialEventFile[] =
    "\xEF\xBB\xBFschema_version,event_id,parent_id,sibling_order,title,importance,"
    "start_at,completed_at,status,note_html,attachments_json,created_at,updated_at\r\n";

constexpr std::array<const char*, expectedColumnCount> expectedHeader{
    "schema_version", "event_id", "parent_id", "sibling_order", "title",
    "importance", "start_at", "completed_at", "status", "note_html",
    "attachments_json", "created_at", "updated_at"
};

[[nodiscard]] application::EventLoadResult failure(
    const std::size_t line, std::string column, std::string message)
{
    application::EventLoadResult result;
    result.error = application::EventLoadError{
        line, std::move(column), std::move(message)};
    return result;
}

[[nodiscard]] application::EventSaveResult saveFailure(std::string message)
{
    application::EventSaveResult result;
    result.error = application::EventSaveError{std::move(message)};
    return result;
}

[[nodiscard]] std::optional<std::string> initializeEventFileIfMissing(
    const std::filesystem::path& eventFile)
{
    std::error_code fileSystemError;
    const auto exists = std::filesystem::exists(eventFile, fileSystemError);
    if (fileSystemError)
        return "event.csv path could not be inspected";
    if (exists)
        return std::nullopt;

    const auto parentDirectory = eventFile.parent_path();
    if (!parentDirectory.empty()) {
        std::filesystem::create_directories(parentDirectory, fileSystemError);
        if (fileSystemError)
            return "event.csv data directory could not be created";
    }

    const auto filePath = QString::fromStdWString(eventFile.wstring());
    QSaveFile output(filePath);
    output.setDirectWriteFallback(false);
    if (!output.open(QIODevice::WriteOnly))
        return output.errorString().toUtf8().toStdString();

    constexpr auto initialEventFileSize = sizeof(initialEventFile) - 1;
    if (output.write(initialEventFile,
                     static_cast<qint64>(initialEventFileSize))
            != static_cast<qint64>(initialEventFileSize)) {
        output.cancelWriting();
        return "event.csv initial header could not be written";
    }
    if (!output.commit())
        return output.errorString().toUtf8().toStdString();

    return std::nullopt;
}

[[nodiscard]] std::optional<QString> decodeUtf8(const std::string& value)
{
    QStringDecoder decoder(QStringDecoder::Utf8);
    const auto decoded = decoder.decode(QByteArray(
        value.data(), static_cast<qsizetype>(value.size())));
    if (decoder.hasError())
        return std::nullopt;
    return decoded;
}

[[nodiscard]] QString fromUtf8Unchecked(const std::string_view value)
{
    return QString::fromUtf8(value.data(), static_cast<qsizetype>(value.size()));
}

[[nodiscard]] bool hasExplicitOffset(const QString& value)
{
    static const QRegularExpression offsetExpression(
        QStringLiteral("(?:Z|[+-]\\d{2}:?\\d{2})$"));
    return offsetExpression.match(value).hasMatch();
}

[[nodiscard]] bool isValidIsoDateTime(const QString& value)
{
    return hasExplicitOffset(value)
        && QDateTime::fromString(value, Qt::ISODate).isValid();
}

[[nodiscard]] std::optional<std::vector<std::string>> decodeAttachments(
    const QString& value)
{
    if (value.trimmed().isEmpty())
        return std::vector<std::string>{};

    QJsonParseError parseError;
    const auto document = QJsonDocument::fromJson(value.toUtf8(), &parseError);
    if (parseError.error != QJsonParseError::NoError || !document.isArray())
        return std::nullopt;

    std::vector<std::string> attachments;
    const auto values = document.array();
    attachments.reserve(static_cast<std::size_t>(values.size()));
    for (const auto& entry : values) {
        if (!entry.isString())
            return std::nullopt;
        const auto path = entry.toString();
        if (!QDir::isAbsolutePath(path))
            return std::nullopt;
        attachments.push_back(path.toUtf8().toStdString());
    }
    return attachments;
}

[[nodiscard]] bool containsUnsafeRichText(const QString& value)
{
    static const QRegularExpression unsafeExpression(
        QStringLiteral("<(?:\\s*)(?:script|img|iframe|object|embed|link|svg|video|audio)\\b|"
                       "(?:src|href)\\s*=|url\\s*\\("),
        QRegularExpression::CaseInsensitiveOption);
    return unsafeExpression.match(value).hasMatch();
}

[[nodiscard]] std::string encodeCsvField(const std::string_view value)
{
    const auto needsQuotes = value.find_first_of(",\"\r\n") != std::string_view::npos;
    if (!needsQuotes)
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

[[nodiscard]] std::string encodeAttachments(
    const std::vector<std::string>& attachments)
{
    QJsonArray values;
    for (const auto& attachment : attachments)
        values.push_back(fromUtf8Unchecked(attachment));
    return QJsonDocument(values).toJson(QJsonDocument::Compact).toStdString();
}

[[nodiscard]] std::string formatSiblingOrder(const double value)
{
    std::array<char, 64> buffer{};
    const auto conversion = std::to_chars(
        buffer.data(), buffer.data() + buffer.size(), value,
        std::chars_format::general, std::numeric_limits<double>::max_digits10);
    if (conversion.ec != std::errc{})
        return {};
    return std::string(buffer.data(), conversion.ptr);
}

[[nodiscard]] std::array<std::string, expectedColumnCount> serialize(
    const domain::EventRecord& event)
{
    return {
        std::to_string(event.schemaVersion), event.eventId, event.parentId,
        formatSiblingOrder(event.siblingOrder), event.title,
        std::to_string(event.importance), event.startAt, event.completedAt,
        event.status, event.noteHtml, encodeAttachments(event.attachments),
        event.createdAt, event.updatedAt
    };
}

[[nodiscard]] std::optional<std::string> validateSnapshot(
    const std::vector<domain::EventRecord>& events)
{
    std::unordered_map<std::string, std::string> parents;
    parents.reserve(events.size());
    for (const auto& event : events) {
        if (event.schemaVersion != CsvEventRepository::supportedSchemaVersion)
            return "snapshot contains an unsupported schema version";
        if (event.eventId.empty()
                || QUuid::fromString(fromUtf8Unchecked(event.eventId)).isNull())
            return "snapshot contains an invalid event_id";
        if (!parents.emplace(event.eventId, event.parentId).second)
            return "snapshot contains a duplicated event_id";
        if (!event.parentId.empty()
                && QUuid::fromString(fromUtf8Unchecked(event.parentId)).isNull())
            return "snapshot contains an invalid parent_id";
        if (!std::isfinite(event.siblingOrder))
            return "snapshot contains an invalid sibling_order";
        if (fromUtf8Unchecked(event.title).trimmed().isEmpty())
            return "snapshot contains an empty title";
        if (event.importance != 1 && event.importance != 3
                && event.importance != 5 && event.importance != 7
                && event.importance != 9)
            return "snapshot contains an invalid importance";

        const auto start = fromUtf8Unchecked(event.startAt);
        const auto completed = fromUtf8Unchecked(event.completedAt);
        if (!isValidIsoDateTime(start))
            return "snapshot contains an invalid start_at";
        if (!completed.isEmpty() && !isValidIsoDateTime(completed))
            return "snapshot contains an invalid completed_at";
        if (fromUtf8Unchecked(event.status) == QStringLiteral("已完成")
                && completed.isEmpty())
            return "snapshot contains a completed event without completed_at";
        if (!completed.isEmpty()) {
            const auto startTime = QDateTime::fromString(start, Qt::ISODate);
            const auto completedTime = QDateTime::fromString(completed, Qt::ISODate);
            if (completedTime < startTime || completedTime > QDateTime::currentDateTime())
                return "snapshot contains an invalid completion time range";
        }
        if (containsUnsafeRichText(fromUtf8Unchecked(event.noteHtml)))
            return "snapshot contains unsafe note_html";
        for (const auto& attachment : event.attachments) {
            if (!QDir::isAbsolutePath(fromUtf8Unchecked(attachment)))
                return "snapshot contains a non-absolute attachment path";
        }
        if (!isValidIsoDateTime(fromUtf8Unchecked(event.createdAt))
                || !isValidIsoDateTime(fromUtf8Unchecked(event.updatedAt)))
            return "snapshot contains invalid audit timestamps";
    }

    for (const auto& [eventId, parentId] : parents) {
        if (!parentId.empty() && !parents.contains(parentId))
            return "snapshot contains a missing parent_id";
        std::unordered_set<std::string> chain;
        auto currentId = eventId;
        while (!currentId.empty()) {
            if (!chain.insert(currentId).second)
                return "snapshot contains a parent cycle";
            const auto parent = parents.find(currentId);
            if (parent == parents.end())
                break;
            currentId = parent->second;
        }
    }
    return std::nullopt;
}

[[nodiscard]] bool writeBytes(QSaveFile& output, const std::string_view value)
{
    return output.write(value.data(), static_cast<qint64>(value.size()))
        == static_cast<qint64>(value.size());
}

[[nodiscard]] bool writeRecord(
    QSaveFile& output,
    const std::array<std::string, expectedColumnCount>& fields)
{
    for (std::size_t index = 0; index < fields.size(); ++index) {
        if (index > 0 && !writeBytes(output, ","))
            return false;
        const auto encoded = encodeCsvField(fields[index]);
        if (!writeBytes(output, encoded))
            return false;
    }
    return writeBytes(output, "\r\n");
}

} // namespace

CsvEventRepository::CsvEventRepository(std::filesystem::path eventFile)
    : eventFile_(std::move(eventFile))
{
}

const std::filesystem::path& CsvEventRepository::eventFile() const noexcept
{
    return eventFile_;
}

application::EventLoadResult CsvEventRepository::load() const
{
    if (const auto initializationError = initializeEventFileIfMissing(eventFile_);
        initializationError.has_value()) {
        return failure(0, {}, *initializationError);
    }

    std::ifstream input(eventFile_, std::ios::binary);
    if (!input.is_open())
        return failure(0, {}, "event.csv could not be opened");

    auto parsed = CsvCodec::parse(input);
    if (parsed.error.has_value())
        return failure(parsed.error->line, {}, parsed.error->message);
    if (parsed.records.empty())
        return failure(1, {}, "event.csv does not contain a header row");

    const auto& header = parsed.records.front();
    if (header.fields.size() != expectedColumnCount)
        return failure(header.line, {},
                       "event.csv header has an unexpected column count");
    for (std::size_t index = 0; index < expectedColumnCount; ++index) {
        if (header.fields[index] != expectedHeader[index])
            return failure(header.line, expectedHeader[index],
                           "event.csv header does not match schema version 1");
    }

    application::EventLoadResult result;
    result.events.reserve(parsed.records.size() - 1);
    std::unordered_map<std::string, std::size_t> sourceLines;

    for (std::size_t recordIndex = 1; recordIndex < parsed.records.size(); ++recordIndex) {
        const auto& record = parsed.records[recordIndex];
        if (record.fields.size() != expectedColumnCount)
            return failure(record.line, {},
                           "event row has an unexpected column count");

        std::array<QString, expectedColumnCount> fields;
        for (std::size_t columnIndex = 0; columnIndex < expectedColumnCount;
             ++columnIndex) {
            const auto decoded = decodeUtf8(record.fields[columnIndex]);
            if (!decoded.has_value())
                return failure(record.line, expectedHeader[columnIndex],
                               "field is not valid UTF-8");
            fields[columnIndex] = *decoded;
        }

        bool converted = false;
        const auto schemaVersion = fields[0].toInt(&converted);
        if (!converted
            || schemaVersion != CsvEventRepository::supportedSchemaVersion)
            return failure(record.line, expectedHeader[0],
                           "unsupported schema_version");

        const auto eventId = fields[1].trimmed();
        if (eventId.isEmpty() || QUuid::fromString(eventId).isNull())
            return failure(record.line, expectedHeader[1],
                           "event_id is not a valid UUID");
        const auto eventIdUtf8 = eventId.toUtf8().toStdString();
        if (sourceLines.contains(eventIdUtf8))
            return failure(record.line, expectedHeader[1],
                           "event_id is duplicated");

        const auto parentId = fields[2].trimmed();
        if (!parentId.isEmpty() && QUuid::fromString(parentId).isNull())
            return failure(record.line, expectedHeader[2],
                           "parent_id is not a valid UUID");

        const auto siblingOrder = fields[3].toDouble(&converted);
        if (!converted || !std::isfinite(siblingOrder))
            return failure(record.line, expectedHeader[3],
                           "sibling_order is not a finite number");

        const auto title = fields[4].trimmed();
        if (title.isEmpty())
            return failure(record.line, expectedHeader[4],
                           "title must not be empty");

        const auto importance = fields[5].toInt(&converted);
        if (!converted || (importance != 1 && importance != 3 && importance != 5
                           && importance != 7 && importance != 9)) {
            return failure(record.line, expectedHeader[5],
                           "importance must be one of 1, 3, 5, 7, or 9");
        }

        if (!isValidIsoDateTime(fields[6]))
            return failure(record.line, expectedHeader[6],
                           "start_at must be ISO 8601 with a UTC offset");
        if (!fields[7].isEmpty() && !isValidIsoDateTime(fields[7]))
            return failure(record.line, expectedHeader[7],
                           "completed_at must be empty or ISO 8601 with a UTC offset");

        const auto status = fields[8].trimmed();
        if (status == QStringLiteral("已完成") && fields[7].isEmpty())
            return failure(record.line, expectedHeader[7],
                           "completed_at is required when status is completed");

        if (!fields[7].isEmpty()) {
            const auto start = QDateTime::fromString(fields[6], Qt::ISODate);
            const auto completed = QDateTime::fromString(fields[7], Qt::ISODate);
            if (completed < start)
                return failure(record.line, expectedHeader[7],
                               "completed_at is earlier than start_at");
            if (completed > QDateTime::currentDateTime())
                return failure(record.line, expectedHeader[7],
                               "completed_at is later than the current time");
        }

        if (containsUnsafeRichText(fields[9]))
            return failure(record.line, expectedHeader[9],
                           "note_html contains remote or active content");

        const auto attachments = decodeAttachments(fields[10]);
        if (!attachments.has_value())
            return failure(record.line, expectedHeader[10],
                           "attachments_json must be an array of absolute paths");

        if (!isValidIsoDateTime(fields[11]))
            return failure(record.line, expectedHeader[11],
                           "created_at must be ISO 8601 with a UTC offset");
        if (!isValidIsoDateTime(fields[12]))
            return failure(record.line, expectedHeader[12],
                           "updated_at must be ISO 8601 with a UTC offset");

        domain::EventRecord event;
        event.schemaVersion = schemaVersion;
        event.eventId = eventIdUtf8;
        event.parentId = parentId.toUtf8().toStdString();
        event.siblingOrder = siblingOrder;
        event.title = title.toUtf8().toStdString();
        event.importance = importance;
        event.startAt = fields[6].toUtf8().toStdString();
        event.completedAt = fields[7].toUtf8().toStdString();
        event.status = status.toUtf8().toStdString();
        event.noteHtml = fields[9].toUtf8().toStdString();
        event.attachments = *attachments;
        event.createdAt = fields[11].toUtf8().toStdString();
        event.updatedAt = fields[12].toUtf8().toStdString();

        sourceLines.emplace(event.eventId, record.line);
        result.events.push_back(std::move(event));
    }

    std::unordered_map<std::string, std::string> parents;
    parents.reserve(result.events.size());
    for (const auto& event : result.events)
        parents.emplace(event.eventId, event.parentId);

    for (const auto& event : result.events) {
        if (!event.parentId.empty() && !parents.contains(event.parentId))
            return failure(sourceLines.at(event.eventId), expectedHeader[2],
                           "parent_id does not reference an existing event");

        std::unordered_set<std::string> chain;
        auto currentId = event.eventId;
        while (!currentId.empty()) {
            if (!chain.insert(currentId).second)
                return failure(sourceLines.at(event.eventId), expectedHeader[2],
                               "parent_id relationships contain a cycle");
            const auto parent = parents.find(currentId);
            if (parent == parents.end())
                break;
            currentId = parent->second;
        }
    }

    return result;
}

application::EventSaveResult CsvEventRepository::save(
    const std::vector<domain::EventRecord>& events) const
{
    if (const auto validationError = validateSnapshot(events);
        validationError.has_value()) {
        return saveFailure(*validationError);
    }

    std::error_code fileSystemError;
    const auto parentDirectory = eventFile_.parent_path();
    if (!parentDirectory.empty()) {
        std::filesystem::create_directories(parentDirectory, fileSystemError);
        if (fileSystemError)
            return saveFailure("event.csv data directory could not be created");
    }

    QSaveFile output(QString::fromStdWString(eventFile_.wstring()));
    output.setDirectWriteFallback(false);
    if (!output.open(QIODevice::WriteOnly))
        return saveFailure(output.errorString().toUtf8().toStdString());
    if (!writeBytes(output, initialEventFile)) {
        output.cancelWriting();
        return saveFailure("event.csv header could not be written");
    }
    for (const auto& event : events) {
        if (!writeRecord(output, serialize(event))) {
            output.cancelWriting();
            return saveFailure("event.csv event row could not be written");
        }
    }
    if (!output.commit())
        return saveFailure(output.errorString().toUtf8().toStdString());

    return {};
}

} // namespace todoit::infrastructure
