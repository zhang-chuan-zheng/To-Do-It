#include "presentation/controllers/QuoteController.h"

#include <QFile>
#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonParseError>
#include <QRandomGenerator>

#include <utility>

namespace todoit::presentation {
namespace {

constexpr auto quoteResourcePath =
    ":/qt/qml/ToDoIt/content/philosophy_quotes.json";

} // namespace

QuoteController::QuoteController(QObject* parent)
    : QObject(parent)
{
    load();
    refreshQuote();
}

QString QuoteController::quote() const
{
    return quote_;
}

QString QuoteController::author() const
{
    return author_;
}

QString QuoteController::source() const
{
    return source_;
}

QString QuoteController::loadError() const
{
    return loadError_;
}

int QuoteController::availableCount() const noexcept
{
    return static_cast<int>(quotes_.size());
}

void QuoteController::refreshQuote()
{
    if (quotes_.isEmpty())
        return;

    auto nextIndex = 0;
    if (quotes_.size() > 1) {
        do {
            nextIndex = QRandomGenerator::global()->bounded(
                static_cast<int>(quotes_.size()));
        } while (nextIndex == currentIndex_);
    }

    currentIndex_ = nextIndex;
    const auto& entry = quotes_.at(currentIndex_);
    quote_ = entry.text;
    author_ = entry.author;
    source_ = entry.source;
    emit quoteChanged();
}

void QuoteController::load()
{
    QFile file(QString::fromLatin1(quoteResourcePath));
    if (!file.open(QIODevice::ReadOnly)) {
        useFallback(QStringLiteral("名言文件无法打开：%1")
                        .arg(QString::fromLatin1(quoteResourcePath)));
        return;
    }

    QJsonParseError parseError;
    const auto document = QJsonDocument::fromJson(file.readAll(), &parseError);
    if (parseError.error != QJsonParseError::NoError || !document.isObject()) {
        useFallback(QStringLiteral("名言文件格式无效：%1")
                        .arg(parseError.errorString()));
        return;
    }

    const auto root = document.object();
    if (root.value(QStringLiteral("schemaVersion")).toInt() != 1) {
        useFallback(QStringLiteral("名言文件 schemaVersion 不受支持"));
        return;
    }

    const auto values = root.value(QStringLiteral("quotes")).toArray();
    const auto declaredCount = root.value(QStringLiteral("count")).toInt(-1);
    if (declaredCount != values.size()) {
        useFallback(QStringLiteral("名言文件 count 与实际记录数不一致"));
        return;
    }

    quotes_.reserve(values.size());
    for (const auto& value : values) {
        if (!value.isObject())
            continue;
        const auto object = value.toObject();
        if (!object.value(QStringLiteral("verified")).toBool(false))
            continue;

        QuoteEntry entry{
            object.value(QStringLiteral("text")).toString().trimmed(),
            object.value(QStringLiteral("author")).toString().trimmed(),
            object.value(QStringLiteral("source")).toString().trimmed(),
        };
        if (entry.text.isEmpty() || entry.author.isEmpty()
            || entry.source.isEmpty()) {
            continue;
        }
        quotes_.push_back(std::move(entry));
    }

    if (quotes_.isEmpty())
        useFallback(QStringLiteral("名言文件中没有可用的已核验记录"));
}

void QuoteController::useFallback(QString error)
{
    loadError_ = std::move(error);
    quotes_.clear();
    quotes_.push_back(QuoteEntry{
        QStringLiteral("专注当下，完成重要的事。"),
        QStringLiteral("To Do It"),
        QStringLiteral("内置回退文本"),
    });
}

} // namespace todoit::presentation
