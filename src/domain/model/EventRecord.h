#pragma once

#include <string>
#include <vector>

namespace todoit::domain {

struct EventRecord final
{
    int schemaVersion{1};
    std::string eventId;
    std::string parentId;
    double siblingOrder{0.0};
    std::string title;
    int importance{5};
    std::string startAt;
    std::string completedAt;
    std::string status;
    std::string noteHtml;
    std::vector<std::string> attachments;
    std::string createdAt;
    std::string updatedAt;
};

} // namespace todoit::domain
