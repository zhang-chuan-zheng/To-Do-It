#pragma once

#include <QString>
#include <QStringList>
#include <QVector>

#include <optional>

namespace todoit::updater {

struct MigrationDescriptor final
{
    QString id;
    int fromSchema{-1};
    int toSchema{-1};
    QStringList removedFields;
};

struct EventColumnDescriptor final
{
    QString name;
    QString defaultValue;
};

struct EventSchemaDescriptor final
{
    int version{-1};
    QVector<EventColumnDescriptor> columns;
};

struct UpdateManifest final
{
    QString appVersion;
    int eventSchema{-1};
    int settingsSchema{-1};
    QVector<EventSchemaDescriptor> eventSchemas;
    QVector<MigrationDescriptor> eventMigrations;
    QString changeSummary;
    QStringList addedFiles;
    QStringList changedFiles;
    QStringList removedFiles;

    [[nodiscard]] static std::optional<UpdateManifest> load(
        const QString& filePath, QString* error);

    [[nodiscard]] const EventSchemaDescriptor* schema(int version) const noexcept;
};

} // namespace todoit::updater
