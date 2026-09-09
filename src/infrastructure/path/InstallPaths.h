#pragma once

#include <filesystem>

namespace todoit::infrastructure {

class InstallPaths final
{
public:
    [[nodiscard]] static InstallPaths fromExecutableDirectory(
        std::filesystem::path executableDirectory);

    [[nodiscard]] const std::filesystem::path& installDirectory() const noexcept;
    [[nodiscard]] std::filesystem::path eventFile() const;

private:
    explicit InstallPaths(std::filesystem::path installDirectory);

    std::filesystem::path installDirectory_;
};

} // namespace todoit::infrastructure
