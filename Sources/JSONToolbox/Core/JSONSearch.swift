import Foundation

/// One hit from a structured search: the location, what matched (key and/or value), and the value.
struct JSONSearchMatch: Identifiable {
    let id = UUID()
    let path: String
    let keyMatch: Bool
    let valueMatch: Bool
    let value: JSONValue

    var valuePreview: String { value.preview }
}

/// Case-insensitive substring search over every key and scalar value in a document.
///
/// Returns matches in document order with the JSONPath-style location of each, so a result can
/// be fed straight back into `JSONQuery`.
enum JSONSearch {
    static func search(_ root: JSONValue, term rawTerm: String) -> [JSONSearchMatch] {
        let term = rawTerm.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !term.isEmpty else { return [] }

        var results: [JSONSearchMatch] = []
        visit(label: nil, path: "$", value: root, term: term, into: &results)
        return results
    }

    private static func visit(label: String?, path: String, value: JSONValue,
                              term: String, into results: inout [JSONSearchMatch]) {
        let keyMatch = label?.lowercased().contains(term) ?? false
        let valueMatch = scalarText(value).map { $0.lowercased().contains(term) } ?? false

        if keyMatch || valueMatch {
            results.append(JSONSearchMatch(path: path, keyMatch: keyMatch, valueMatch: valueMatch, value: value))
        }

        switch value {
        case let .object(pairs):
            for pair in pairs {
                visit(label: pair.key, path: "\(path).\(pair.key)", value: pair.value, term: term, into: &results)
            }
        case let .array(items):
            for (index, item) in items.enumerated() {
                visit(label: nil, path: "\(path)[\(index)]", value: item, term: term, into: &results)
            }
        default:
            break
        }
    }

    /// The searchable text of a scalar, or `nil` for containers (which have no value of their own).
    private static func scalarText(_ value: JSONValue) -> String? {
        switch value {
        case let .string(s): s
        case let .number(n): n
        case let .bool(b): b ? "true" : "false"
        case .null: "null"
        case .object, .array: nil
        }
    }
}
