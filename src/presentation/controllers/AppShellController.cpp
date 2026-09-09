#include "presentation/controllers/AppShellController.h"

namespace todoit::presentation {

AppShellController::AppShellController(QObject* parent)
    : QObject(parent)
{
}

QString AppShellController::applicationName() const
{
    return QStringLiteral("To Do It");
}

QString AppShellController::applicationVersion() const
{
    return QStringLiteral(TODOIT_PROJECT_VERSION);
}

QString AppShellController::stageDescription() const
{
    return QStringLiteral("整体应用框架已就绪");
}

bool AppShellController::backendReady() const noexcept
{
    return true;
}

} // namespace todoit::presentation


