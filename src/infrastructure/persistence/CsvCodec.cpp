#include "infrastructure/persistence/CsvCodec.h"

#include <iterator>
#include <utility>

namespace todoit::infrastructure {
namespace {

constexpr unsigned char utf8BomFirst = 0xEF;
constexpr unsigned char utf8BomSecond = 0xBB;
constexpr unsigned char utf8BomThird = 0xBF;

[[nodiscard]] bool hasUtf8Bom(const std::string& content) noexcept
{
    return content.size() >= 3
        && static_cast<unsigned char>(content[0]) == utf8BomFirst
        && static_cast<unsigned char>(content[1]) == utf8BomSecond
        && static_cast<unsigned char>(content[2]) == utf8BomThird;
}

} // namespace

CsvParseResult CsvCodec::parse(std::istream& input)
{
    CsvParseResult result;
    auto content = std::string(std::istreambuf_iterator<char>(input),
                               std::istreambuf_iterator<char>());
    if (!hasUtf8Bom(content)) {
        result.error = CsvParseError{1, "event.csv must use UTF-8 with BOM"};
        return result;
    }
    content.erase(0, 3);

    CsvRecord record;
    std::string field;
    std::size_t line = 1;
    bool inQuotedField = false;
    bool quotedFieldClosed = false;
    bool fieldStarted = false;

    const auto finishRecord = [&result, &record, &field, &fieldStarted,
                               &quotedFieldClosed, &line]() {
        record.fields.push_back(std::move(field));
        field.clear();
        if (!(record.fields.size() == 1 && record.fields.front().empty()))
            result.records.push_back(std::move(record));
        record = CsvRecord{line + 1, {}};
        fieldStarted = false;
        quotedFieldClosed = false;
    };

    for (std::size_t index = 0; index < content.size(); ++index) {
        const auto character = content[index];

        if (inQuotedField) {
            if (character == '"') {
                if (index + 1 < content.size() && content[index + 1] == '"') {
                    field.push_back('"');
                    ++index;
                } else {
                    inQuotedField = false;
                    quotedFieldClosed = true;
                }
            } else {
                field.push_back(character);
                if (character == '\n')
                    ++line;
            }
            continue;
        }

        if (quotedFieldClosed && character != ',' && character != '\r'
                && character != '\n') {
            result.error = CsvParseError{line,
                "unexpected character after a closing quote"};
            result.records.clear();
            return result;
        }

        if (character == '"') {
            if (fieldStarted || !field.empty()) {
                result.error = CsvParseError{line,
                    "quote found inside an unquoted field"};
                result.records.clear();
                return result;
            }
            inQuotedField = true;
            fieldStarted = true;
        } else if (character == ',') {
            record.fields.push_back(std::move(field));
            field.clear();
            fieldStarted = false;
            quotedFieldClosed = false;
        } else if (character == '\r' || character == '\n') {
            if (character == '\r' && index + 1 < content.size()
                    && content[index + 1] == '\n') {
                ++index;
            }
            finishRecord();
            ++line;
            record.line = line;
        } else {
            field.push_back(character);
            fieldStarted = true;
        }
    }

    if (inQuotedField) {
        result.error = CsvParseError{line, "unterminated quoted field"};
        result.records.clear();
        return result;
    }

    if (fieldStarted || quotedFieldClosed || !field.empty()
            || !record.fields.empty()) {
        record.fields.push_back(std::move(field));
        result.records.push_back(std::move(record));
    }

    return result;
}

} // namespace todoit::infrastructure
