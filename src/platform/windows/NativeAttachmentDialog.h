#pragma once

#include <QObject>
#include <QString>
#include <QVariantList>

namespace todoit::platform::windows {

class NativeAttachmentDialog final : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString lastError READ lastError NOTIFY lastErrorChanged)

public:
    explicit NativeAttachmentDialog(QObject* parent = nullptr);

    [[nodiscard]] QString lastError() const;
    Q_INVOKABLE QVariantList chooseAttachments();

signals:
    void lastErrorChanged();

private:
    void setLastError(QString message);

    QString lastError_;
};

} // namespace todoit::platform::windows
