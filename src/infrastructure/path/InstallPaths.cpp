#include "infrastructure/path/InstallPaths.h"

#include <utility>

namespace todoit::infrastructure {

InstallPaths::InstallPaths(std::filesystem::path installDirectory)
    : installDirectory_(std::move(installDirectory))
{
}

InstallPaths InstallPaths::fromExecutableDirectory(
    std::filesystem::path executableDirectory)
{
    return InstallPaths(std::move(executableDirectory));
}

const std::filesystem::path& InstallPaths::installDirectory() const noexcept
{
    return installDirectory_;
}

std::filesystem::path InstallPaths::eventFile() const
{
    return installDirectory_ / "data" / "event.csv";
}

} // namespace todoit::infrastructure
