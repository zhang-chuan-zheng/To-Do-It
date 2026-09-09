#include "presentation/controllers/RichTextFormatter.h"

#include <QFont>
#include <QQuickTextDocument>
#include <QTextCharFormat>
#include <QTextCursor>
#include <QTextDocument>

#include <algorithm>

namespace todoit::presentation {
namespace {

[[nodiscard]] QTextCursor selectedCursor(QObject* quickTextDocument,
                                         const int selectionStart,
                                         const int selectionEnd)
{
    const auto documentWrapper = qobject_cast<QQuickTextDocument*>(quickTextDocument);
    if (documentWrapper == nullptr || documentWrapper->textDocument() == nullptr)
        return {};

    auto* document = documentWrapper->textDocument();
    const auto lastTextPosition = std::max(0, document->characterCount() - 1);
    const auto start = std::clamp(std::min(selectionStart, selectionEnd),
                                  0, lastTextPosition);
    const auto end = std::clamp(std::max(selectionStart, selectionEnd),
                                0, lastTextPosition);
    if (start == end)
        return {};

    QTextCursor cursor(document);
    cursor.setPosition(start);
    cursor.setPosition(end, QTextCursor::KeepAnchor);
    return cursor;
}

} // namespace

RichTextFormatter::RichTextFormatter(QObject* parent)
    : QObject(parent)
{
}

bool RichTextFormatter::toggleBold(QObject* quickTextDocument,
                                   const int selectionStart,
                                   const int selectionEnd) const
{
    auto cursor = selectedCursor(quickTextDocument, selectionStart, selectionEnd);
    if (!cursor.hasSelection())
        return false;

    const auto currentlyBold = cursor.charFormat().fontWeight() >= QFont::Bold;
    QTextCharFormat format;
    format.setFontWeight(currentlyBold ? QFont::Normal : QFont::Bold);
    cursor.beginEditBlock();
    cursor.mergeCharFormat(format);
    cursor.endEditBlock();
    return true;
}

bool RichTextFormatter::applyColor(QObject* quickTextDocument,
                                   const int selectionStart,
                                   const int selectionEnd,
                                   const QColor& color) const
{
    if (!color.isValid())
        return false;
    auto cursor = selectedCursor(quickTextDocument, selectionStart, selectionEnd);
    if (!cursor.hasSelection())
        return false;

    QTextCharFormat format;
    format.setForeground(color);
    cursor.beginEditBlock();
    cursor.mergeCharFormat(format);
    cursor.endEditBlock();
    return true;
}

} // namespace todoit::presentation
