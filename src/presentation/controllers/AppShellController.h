#pragma once

#include <QObject>
#include <QString>

namespace todoit::presentation {

class AppShellController final : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString applicationName READ applicationName CONSTANT FINAL)
    Q_PROPERTY(QString applicationVersion READ applicationVersion CONSTANT FINAL)
    Q_PROPERTY(QString stageDescription READ stageDescription CONSTANT FINAL)
    Q_PROPERTY(bool backendReady READ backendReady CONSTANT FINAL)

public:
    explicit AppShellController(QObject* parent = nullptr);

    [[nodiscard]] QString applicationName() const;
    [[nodiscard]] QString applicationVersion() const;
    [[nodiscard]] QString stageDescription() const;
    [[nodiscard]] bool backendReady() const noexcept;
};

} // namespace todoit::presentation


