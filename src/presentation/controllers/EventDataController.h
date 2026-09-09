#pragma once

#include "application/port/IEventRepository.h"

#include <QObject>
#include <QHash>
#include <QString>
#include <QVariantList>

#include <filesystem>

namespace todoit::presentation {

class EventDataController final : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QVariantList events READ events CONSTANT FINAL)
    Q_PROPERTY(QString eventFilePath READ eventFilePath CONSTANT FINAL)
    Q_PROPERTY(QString loadError READ loadError CONSTANT FINAL)
    Q_PROPERTY(QString saveError READ saveError NOTIFY saveErrorChanged FINAL)
    Q_PROPERTY(bool loaded READ loaded CONSTANT FINAL)

public:
    EventDataController(const application::IEventRepository& repository,
                        application::EventLoadResult loadResult,
                        std::filesystem::path eventFilePath,
                        QObject* parent = nullptr);

    [[nodiscard]] QVariantList events() const;
    [[nodiscard]] QString eventFilePath() const;
    [[nodiscard]] QString loadError() const;
    [[nodiscard]] QString saveError() const;
    [[nodiscard]] bool loaded() const noexcept;

    Q_INVOKABLE QString createEventId() const;
    Q_INVOKABLE QString currentChinaDateTime() const;
    Q_INVOKABLE bool saveEvents(const QVariantList& rows);

signals:
    void saveErrorChanged();

private:
    void setSaveError(QString error);

    const application::IEventRepository& repository_;
    QVariantList events_;
    QString eventFilePath_;
    QString loadError_;
    QString saveError_;
    QHash<QString, QString> createdAtByEventId_;
    bool loaded_{false};
};

} // namespace todoit::presentation
