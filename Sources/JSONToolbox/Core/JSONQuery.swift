import Foundation

/// Evaluates a lightweight path expression against a `JSONValue`.
///
/// Supported syntax (a small subset of JSONPath):
///   - `$` optional root marker
///   - `.key` or `key` for object members
///   - `["key"]` / `['key']` for members with special characters
///   - `[0]` for array indices
///
/// Example: `$.store.book[0].title`
enum JSONQuery {
    private struct QueryError: Error { let message: String }

    private enum Component {
        case key(String)
        case index(Int)
    }

    /// The result of evaluating a path: either the located value or a human-readable reason.
    enum Outcome {
        case value(JSONValue)
        case failure(String)
    }

    static func evaluate(_ path: String, on value: JSONValue) -> Outcome {
        let trimmed = path.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return .value(value) }

        let components: [Component]
        do {
            components = try parse(trimmed)
        } catch let error as QueryError {
            return .failure(error.message)
        } catch {
            return .failure("Invalid path")
        }

        var current = value
        for component in components {
            switch component {
            case let .key(key):
                guard case let .object(pairs) = current,
                      let found = pairs.first(where: { $0.key == key })?.value else {
                    return .failure("Key '\(key)' not found")
                }
                current = found
            case let .index(index):
                guard case let .array(items) = current, index >= 0, index < items.count else {
                    return .failure("Index [\(index)] out of range")
                }
                current = items[index]
            }
        }
        return .value(current)
    }

    private static func parse(_ path: String) throws -> [Component] {
        var components: [Component] = []
        let chars = Array(path)
        var i = 0
        if i < chars.count, chars[i] == "$" { i += 1 }

        while i < chars.count {
            let c = chars[i]
            if c == "." {
                i += 1
            } else if c == "[" {
                i += 1
                if i < chars.count, chars[i] == "\"" || chars[i] == "'" {
                    let quote = chars[i]
                    i += 1
                    var key = ""
                    while i < chars.count, chars[i] != quote { key.append(chars[i]); i += 1 }
                    guard i < chars.count else { throw QueryError(message: "Unclosed quote in path") }
                    i += 1 // closing quote
                    guard i < chars.count, chars[i] == "]" else { throw QueryError(message: "Expected ']'") }
                    i += 1
                    components.append(.key(key))
                } else {
                    var raw = ""
                    while i < chars.count, chars[i] != "]" { raw.append(chars[i]); i += 1 }
                    guard i < chars.count else { throw QueryError(message: "Expected ']'") }
                    i += 1
                    guard let index = Int(raw.trimmingCharacters(in: .whitespaces)) else {
                        throw QueryError(message: "Invalid array index '\(raw)'")
                    }
                    components.append(.index(index))
                }
            } else {
                var key = ""
                while i < chars.count, chars[i] != ".", chars[i] != "[" { key.append(chars[i]); i += 1 }
                components.append(.key(key))
            }
        }
        return components
    }
}
