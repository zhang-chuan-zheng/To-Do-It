#pragma once

#include <QObject>
#include <QString>
#include <QVector>

namespace todoit::presentation {

class QuoteController final : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString quote READ quote NOTIFY quoteChanged FINAL)
    Q_PROPERTY(QString author READ author NOTIFY quoteChanged FINAL)
    Q_PROPERTY(QString source READ source NOTIFY quoteChanged FINAL)
    Q_PROPERTY(QString loadError READ loadError CONSTANT FINAL)
    Q_PROPERTY(int availableCount READ availableCount CONSTANT FINAL)

public:
    explicit QuoteController(QObject* parent = nullptr);

    [[nodiscard]] QString quote() const;
    [[nodiscard]] QString author() const;
    [[nodiscard]] QString source() const;
    [[nodiscard]] QString loadError() const;
    [[nodiscard]] int availableCount() const noexcept;

    Q_INVOKABLE void refreshQuote();

signals:
    void quoteChanged();

private:
    struct QuoteEntry final
    {
        QString text;
        QString author;
        QString source;
    };

    void load();
    void useFallback(QString error);

    QVector<QuoteEntry> quotes_;
    QString quote_;
    QString author_;
    QString source_;
    QString loadError_;
    int currentIndex_{-1};
};

} // namespace todoit::presentation
