#pragma once

#include "domain/model/EventRecord.h"

#include <cstddef>
#include <optional>
#include <string>
#include <vector>

namespace todoit::application {

struct EventLoadError final
{
    std::size_t line{0};
    std::string column;
    std::string message;
};

struct EventLoadResult final
{
    std::vector<domain::EventRecord> events;
    std::optional<EventLoadError> error;

    [[nodiscard]] bool succeeded() const noexcept
    {
        return !error.has_value();
    }
};

struct EventSaveError final
{
    std::string message;
};

struct EventSaveResult final
{
    std::optional<EventSaveError> error;

    [[nodiscard]] bool succeeded() const noexcept
    {
        return !error.has_value();
    }
};

class IEventRepository
{
public:
    virtual ~IEventRepository() = default;

    [[nodiscard]] virtual EventLoadResult load() const = 0;
    [[nodiscard]] virtual EventSaveResult save(
        const std::vector<domain::EventRecord>& events) const = 0;
};

} // namespace todoit::application
