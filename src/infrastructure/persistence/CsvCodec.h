#pragma once

#include <cstddef>
#include <istream>
#include <optional>
#include <string>
#include <vector>

namespace todoit::infrastructure {

struct CsvRecord final
{
    std::size_t line{1};
    std::vector<std::string> fields;
};

struct CsvParseError final
{
    std::size_t line{1};
    std::string message;
};

struct CsvParseResult final
{
    std::vector<CsvRecord> records;
    std::optional<CsvParseError> error;
};

class CsvCodec final
{
public:
    [[nodiscard]] static CsvParseResult parse(std::istream& input);
};

} // namespace todoit::infrastructure
