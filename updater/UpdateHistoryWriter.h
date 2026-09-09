#pragma once

#include "UpdateReport.h"

#include <QString>

namespace todoit::updater {

class UpdateHistoryWriter final
{
public:
    [[nodiscard]] static bool append(const QString& dataDirectory,
                                     const UpdateReport& report,
                                     QString* error);
};

} // namespace todoit::updater
