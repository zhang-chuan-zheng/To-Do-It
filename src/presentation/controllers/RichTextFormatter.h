#pragma once

#include <QColor>
#include <QObject>

namespace todoit::presentation {

class RichTextFormatter final : public QObject
{
    Q_OBJECT

public:
    explicit RichTextFormatter(QObject* parent = nullptr);

    Q_INVOKABLE bool toggleBold(QObject* quickTextDocument,
                                int selectionStart,
                                int selectionEnd) const;
    Q_INVOKABLE bool applyColor(QObject* quickTextDocument,
                                int selectionStart,
                                int selectionEnd,
                                const QColor& color) const;
};

} // namespace todoit::presentation
