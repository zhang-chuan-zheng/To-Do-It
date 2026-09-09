#pragma once

#include "application/port/IEventRepository.h"

#include <filesystem>

namespace todoit::infrastructure {

class CsvEventRepository final : public application::IEventRepository
{
public:
    static constexpr int supportedSchemaVersion = 1;

    explicit CsvEventRepository(std::filesystem::path eventFile);

    [[nodiscard]] application::EventLoadResult load() const override;
    [[nodiscard]] application::EventSaveResult save(
        const std::vector<domain::EventRecord>& events) const override;
    [[nodiscard]] const std::filesystem::path& eventFile() const noexcept;

private:
    std::filesystem::path eventFile_;
};

} // namespace todoit::infrastructure
