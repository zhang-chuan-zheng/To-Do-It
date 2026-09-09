#include "presentation/controllers/EventDataController.h"

#include <QDateTime>
#include <QDir>
#include <QStringList>
#include <QTimeZone>
#include <QUrl>
#include <QVariantMap>
#include <QUuid>

#include <algorithm>
#include <optional>
#include <utility>

namespace todoit::presentation {
namespace {

[[nodiscard]] QString fromUtf8(const std::string& value)
{
    return QString::fromUtf8(value.data(), static_cast<qsizetype>(value.size()));
}

[[nodiscard]] QDateTime parseDateTime(const std::string& value)
{
    return QDateTime::fromString(fromUtf8(value), Qt::ISODate);
}

[[nodiscard]] std::string toUtf8(const QString& value)
{
    return value.toUtf8().toStdString();
}

[[nodiscard]] const QTimeZone& chinaTimeZone()
{
    static const QTimeZone timeZone(QByteArrayLiteral("Asia/Shanghai"));
    return timeZone;
}

[[nodiscard]] QDateTime currentChinaDateTimeValue()
{
    return QDateTime::currentDateTimeUtc().toTimeZone(chinaTimeZone());
}

[[nodiscard]] QString currentIsoDateTime()
{
    // Keep the explicit +08:00 offset required by snapshot validation while
    // making every persisted audit timestamp China Standard Time.
    return currentChinaDateTimeValue().toString(Qt::ISODate);
}

[[nodiscard]] std::optional<QString> storageDateTime(
    const QString& displayValue, const bool allowEmpty)
{
    const auto value = displayValue.trimmed();
    if (value.isEmpty() || value == QStringLiteral("—"))
        return allowEmpty ? std::optional<QString>(QString{}) : std::nullopt;

    const auto parsed = QDateTime::fromString(
        value, QStringLiteral("yyyy-MM-dd HH:mm"));
    if (!parsed.isValid())
        return std::nullopt;
    const QDateTime chinaDateTime(
        parsed.date(), parsed.time(), chinaTimeZone());
    if (!chinaDateTime.isValid())
        return std::nullopt;
    return chinaDateTime.toString(Qt::ISODate);
}

[[nodiscard]] std::optional<std::vector<std::string>> attachmentPaths(
    const QString& serializedUrls)
{
    std::vector<std::string> paths;
    const auto urls = serializedUrls.split(QLatin1Char('|'), Qt::SkipEmptyParts);
    paths.reserve(static_cast<std::size_t>(urls.size()));
    for (const auto& value : urls) {
        const QUrl url(value);
        const auto path = url.isLocalFile() ? url.toLocalFile() : value;
        if (!QDir::isAbsolutePath(path))
            return std::nullopt;
        paths.push_back(toUtf8(QDir::toNativeSeparators(path)));
    }
    return paths;
}

[[nodiscard]] QString displayDateTime(const std::string& value)
{
    if (value.empty())
        return QStringLiteral("—");
    return parseDateTime(value).toTimeZone(chinaTimeZone()).toString(
        QStringLiteral("yyyy-MM-dd HH:mm"));
}

[[nodiscard]] QString normalizedChinaIsoDateTime(const std::string& value)
{
    const auto parsed = parseDateTime(value);
    return parsed.isValid()
        ? parsed.toTimeZone(chinaTimeZone()).toString(Qt::ISODate)
        : fromUtf8(value);
}

[[nodiscard]] QString durationText(const domain::EventRecord& event,
                                   const QDateTime& now)
{
    const auto start = parseDateTime(event.startAt);
    const auto end = event.completedAt.empty() ? now : parseDateTime(event.completedAt);
    if (event.completedAt.empty() && start > now)
        return QStringLiteral("尚未开始");

    const auto totalMinutes = std::max<qint64>(0, start.secsTo(end) / 60);
    const auto days = totalMinutes / (24 * 60);
    const auto hours = (totalMinutes / 60) % 24;
    const auto minutes = totalMinutes % 60;
    return QStringLiteral("%1 天 %2 时 %3 分")
        .arg(days, 3, 10, QChar('0'))
        .arg(hours, 2, 10, QChar('0'))
        .arg(minutes, 2, 10, QChar('0'));
}

[[nodiscard]] QString attachmentText(const domain::EventRecord& event)
{
    QStringList attachments;
    attachments.reserve(static_cast<qsizetype>(event.attachments.size()));
    for (const auto& path : event.attachments)
        attachments.push_back(QUrl::fromLocalFile(fromUtf8(path)).toString());
    return attachments.join(QLatin1Char('|'));
}

[[nodiscard]] QString loadErrorText(const application::EventLoadError& error,
                                    const QString& filePath)
{
    auto location = error.line > 0
        ? QStringLiteral("第 %1 行").arg(error.line)
        : QStringLiteral("文件");
    if (!error.column.empty())
        location += QStringLiteral("，列 %1").arg(fromUtf8(error.column));
    return QStringLiteral("event.csv 加载失败（%1）：%2。路径：%3")
        .arg(location, fromUtf8(error.message), filePath);
}

} // namespace

EventDataController::EventDataController(const application::IEventRepository& repository,
                                         application::EventLoadResult loadResult,
                                         std::filesystem::path eventFilePath,
                                         QObject* parent)
    : QObject(parent)
    , repository_(repository)
    , eventFilePath_(QString::fromStdWString(eventFilePath.wstring()))
    , loaded_(loadResult.succeeded())
{
    if (loadResult.error.has_value()) {
        loadError_ = loadErrorText(*loadResult.error, eventFilePath_);
        return;
    }

    const auto now = currentChinaDateTimeValue();
    events_.reserve(static_cast<qsizetype>(loadResult.events.size()));
    for (const auto& event : loadResult.events) {
        createdAtByEventId_.insert(
            fromUtf8(event.eventId), normalizedChinaIsoDateTime(event.createdAt));
        QVariantMap row;
        row.insert(QStringLiteral("eventKey"), fromUtf8(event.eventId));
        row.insert(QStringLiteral("parentId"), fromUtf8(event.parentId));
        row.insert(QStringLiteral("titleText"), fromUtf8(event.title));
        row.insert(QStringLiteral("importance"), (event.importance + 1) / 2);
        row.insert(QStringLiteral("startAt"), displayDateTime(event.startAt));
        row.insert(QStringLiteral("completedAt"), displayDateTime(event.completedAt));
        row.insert(QStringLiteral("stateText"), event.status.empty()
            ? QStringLiteral("进行中") : fromUtf8(event.status));
        row.insert(QStringLiteral("duration"), durationText(event, now));
        row.insert(QStringLiteral("note"), fromUtf8(event.noteHtml));
        row.insert(QStringLiteral("files"), attachmentText(event));
        row.insert(QStringLiteral("manualOrder"), event.siblingOrder);
        row.insert(QStringLiteral("isDraft"), false);
        events_.push_back(std::move(row));
    }
}

QVariantList EventDataController::events() const
{
    return events_;
}

QString EventDataController::eventFilePath() const
{
    return eventFilePath_;
}

QString EventDataController::loadError() const
{
    return loadError_;
}

QString EventDataController::saveError() const
{
    return saveError_;
}

bool EventDataController::loaded() const noexcept
{
    return loaded_;
}

QString EventDataController::createEventId() const
{
    return QUuid::createUuid().toString(QUuid::WithoutBraces);
}

QString EventDataController::currentChinaDateTime() const
{
    return currentChinaDateTimeValue().toString(
        QStringLiteral("yyyy-MM-dd HH:mm"));
}

bool EventDataController::saveEvents(const QVariantList& rows)
{
    if (!loaded_) {
        setSaveError(QStringLiteral("event.csv 尚未成功加载，为防止覆盖原数据，本次修改没有保存。"));
        return false;
    }

    const auto updatedAt = currentIsoDateTime();
    std::vector<domain::EventRecord> events;
    events.reserve(static_cast<std::size_t>(rows.size()));
    QHash<QString, QString> nextCreatedAtByEventId;

    for (const auto& value : rows) {
        const auto row = value.toMap();
        const auto eventId = row.value(QStringLiteral("eventKey")).toString().trimmed();
        const auto parentId = row.value(QStringLiteral("parentId")).toString().trimmed();
        const auto title = row.value(QStringLiteral("titleText")).toString().trimmed();
        const auto startAt = storageDateTime(
            row.value(QStringLiteral("startAt")).toString(), false);
        const auto completedAt = storageDateTime(
            row.value(QStringLiteral("completedAt")).toString(), true);
        const auto attachments = attachmentPaths(
            row.value(QStringLiteral("files")).toString());
        const auto importanceIndex = row.value(QStringLiteral("importance")).toInt();

        if (eventId.isEmpty() || QUuid::fromString(eventId).isNull()) {
            setSaveError(QStringLiteral("存在无效事项编号，本次修改没有保存。"));
            return false;
        }
        if (!parentId.isEmpty() && QUuid::fromString(parentId).isNull()) {
            setSaveError(QStringLiteral("事项“%1”的父事项编号无效，本次修改没有保存。")
                             .arg(title));
            return false;
        }
        if (title.isEmpty()) {
            setSaveError(QStringLiteral("事项名称不能为空，本次修改没有保存。"));
            return false;
        }
        if (importanceIndex < 1 || importanceIndex > 5) {
            setSaveError(QStringLiteral("事项“%1”的重要程度无效，本次修改没有保存。")
                             .arg(title));
            return false;
        }
        if (!startAt.has_value() || !completedAt.has_value()) {
            setSaveError(QStringLiteral("事项“%1”的时间格式无效，本次修改没有保存。")
                             .arg(title));
            return false;
        }
        if (!attachments.has_value()) {
            setSaveError(QStringLiteral("事项“%1”包含无效附件路径，本次修改没有保存。")
                             .arg(title));
            return false;
        }

        auto status = row.value(QStringLiteral("stateText")).toString().trimmed();
        if (status == QStringLiteral("进行中"))
            status.clear();
        if (status == QStringLiteral("已完成") && completedAt->isEmpty()) {
            setSaveError(QStringLiteral("事项“%1”已完成但没有完成时间，本次修改没有保存。")
                             .arg(title));
            return false;
        }

        const auto createdAt = createdAtByEventId_.value(eventId, updatedAt);
        domain::EventRecord event;
        event.eventId = toUtf8(eventId);
        event.parentId = toUtf8(parentId);
        event.siblingOrder = row.value(QStringLiteral("manualOrder")).toDouble();
        event.title = toUtf8(title);
        event.importance = importanceIndex * 2 - 1;
        event.startAt = toUtf8(*startAt);
        event.completedAt = toUtf8(*completedAt);
        event.status = toUtf8(status);
        event.noteHtml = toUtf8(row.value(QStringLiteral("note")).toString());
        event.attachments = *attachments;
        event.createdAt = toUtf8(createdAt);
        event.updatedAt = toUtf8(updatedAt);
        events.push_back(std::move(event));
        nextCreatedAtByEventId.insert(eventId, createdAt);
    }

    const auto result = repository_.save(events);
    if (!result.succeeded()) {
        setSaveError(QStringLiteral("event.csv 保存失败：%1。路径：%2")
                         .arg(fromUtf8(result.error->message), eventFilePath_));
        return false;
    }

    createdAtByEventId_ = std::move(nextCreatedAtByEventId);
    setSaveError({});
    return true;
}

void EventDataController::setSaveError(QString error)
{
    if (saveError_ == error)
        return;
    saveError_ = std::move(error);
    emit saveErrorChanged();
}

} // namespace todoit::presentation
