//
//  Created by Бодров Александр Сергеевич on 04.02.2025.
//

import JSONutils

extension JSONDictionary {
    /// Left-hand outer merge
    func mergedSpecOverwriting(_ other: JSONDictionary) -> JSONDictionary {
        var merged = other

        for (key, value) in self {
            if key.hasSuffix(":REPLACE") {
                let newKey = key[key.startIndex ..< key.index(key.endIndex, offsetBy: -8)]
                merged[String(newKey)] = value
            } else if let newDict = value as? [String: Any], var baseDict = merged[key] as? [String: Any] {
                newDict.mergedSpecInplaceOverwriting(&baseDict)
                merged[key] = baseDict
            } else if let array = value as? [Any], let base = merged[key] as? [Any] {
                merged[key] = (base + array)
            } else {
                merged[key] = value
            }
        }
        return merged
    }

    /// Left-hand outer merge inplace
    func mergedSpecInplaceOverwriting(_ other: inout JSONDictionary) {
        other.reserveCapacity(Swift.max(other.capacity, self.capacity))

        for (key, value) in self {
            if key.hasSuffix(":REPLACE") {
                let newKey = key[key.startIndex ..< key.index(key.endIndex, offsetBy: -8)]
                other[String(newKey)] = value
            } else if let newDict = value as? [String: Any], var baseDict = other[key] as? [String: Any] {
                newDict.mergedSpecInplaceOverwriting(&baseDict)
                other[key] = baseDict
            } else if let array = value as? [Any], let base = other[key] as? [Any] {
                other[key] = (base + array)
            } else {
                other[key] = value
            }
        }
    }

    /// Раскрываем VARs в словаре (both Keys & Values)
    func expandVariables(_ variables: [String: String]) -> JSONDictionary {
        guard !variables.isEmpty else { return self }

        var expanded: JSONDictionary = self

        for (key, value) in self {
            let newKey = expandVariables(variables, in: key)
            if newKey != key {
                expanded.removeValue(forKey: key)
            }
            expanded[newKey] = expandVariables(variables, in: value)
        }

        return expanded
    }

    /// Раскрываем VARs в переданном значении
    private func expandVariables(_ variables: [String: String], in value: Any) -> Any {
        switch value {
        case let dictionary as JSONDictionary:
            dictionary.expandVariables(variables)
        case let string as String:
            expandVariables(variables, in: string)
        case let array as [JSONDictionary]:
            array.map { $0.expandVariables(variables) }
        case let array as [String]:
            array.map { self.expandVariables(variables, in: $0) }
        case let anyArray as [Any]:
            anyArray.map { self.expandVariables(variables, in: $0) }
        default:
            value
        }
    }

    /// Раскрываем VARs в строке
    private func expandVariables(_ variables: [String: String], in string: String) -> String {
        guard var index = string.firstIndex(of: "$") else { return string }
        var result = string

        while index < result.endIndex {
            let substring = result[index...]
            let lastCharIndex = substring.index(before: substring.endIndex)

            guard substring[index] == "$",
                  let bracketsLeftIndex = substring.index(index, offsetBy: 1, limitedBy: lastCharIndex),
                  substring[bracketsLeftIndex] == "{",
                  let bracketsRightIndex = substring.index(index, offsetBy: 2, limitedBy: lastCharIndex),
                  substring[bracketsRightIndex] != "}"
            else {
                // Move on to the next $ and start again or finish early
                if let nextDollarIndex = result[result.index(after: index)...].firstIndex(of: "$") {
                    index = nextDollarIndex
                    continue
                } else {
                    break
                }
            }

            // This is the start of a variable expansion...
            let variableStart = index
            guard let variableEnd = substring.firstIndex(of: "}") else {
                // Malformed variable, skip the whole string
                break
            }
            // ...with an end
            let nameStart = result.index(variableStart, offsetBy: 2) // Skipping ${
            let nameEnd = result.index(variableEnd, offsetBy: -1) // Removing trailing }

            if let value = variables[String(result[nameStart ... nameEnd])] {
                result.replaceSubrange(variableStart ... variableEnd, with: value)
                index = result.index(index, offsetBy: value.count)
            } else {
                // Skip this whole variable for which we don't have a value
                index = result.index(after: variableEnd)
            }
        }

        return result
    }
}
