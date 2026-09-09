#pragma once

#include "UpdateManifest.h"
#include "infrastructure/persistence/CsvCodec.h"

#include <QByteArray>
#include <QString>

namespace todoit::updater {

struct EventCsvMigrationResult final
{
    bool success{false};
    QByteArray content;
    qsizetype eventCount{0};
    QString error;
};

class EventCsvMigrator final
{
public:
    [[nodiscard]] static EventCsvMigrationResult migrate(
        const infrastructure::CsvParseResult& source,
        const EventSchemaDescriptor& targetSchema);
};

} // namespace todoit::updater
