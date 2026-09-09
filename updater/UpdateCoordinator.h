#pragma once

#include "UpdateReport.h"

#include <QString>

namespace todoit::updater {

struct UpdateOptions final
{
    QString dataDirectory;
    QString manifestFile;
    QString mode;
};

class UpdateCoordinator final
{
public:
    [[nodiscard]] UpdateReport execute(const UpdateOptions& options) const;
};

} // namespace todoit::updater
