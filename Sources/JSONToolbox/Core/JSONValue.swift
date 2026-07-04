import Foundation

/// An order-preserving JSON model.
///
/// `Foundation.JSONSerialization` returns unordered dictionaries, which is a poor fit
/// for a JSON editor where key order and exact number formatting matter. This model keeps
/// object keys in their original order and preserves the raw text of numbers so that
/// values like `1.0`, `1e3`, or very large integers round-trip losslessly.
indirect enum JSONValue: Equatable {
    case object([(key: String, value: JSONValue)])
    case array([JSONValue])
    case string(String)
    case number(String) // raw source text, e.g. "1.0", "-3e10"
    case bool(Bool)
    case null

    static func == (lhs: JSONValue, rhs: JSONValue) -> Bool {
        switch (lhs, rhs) {
        case let (.object(a), .object(b)):
            guard a.count == b.count else { return false }
            for (x, y) in zip(a, b) where x.key != y.key || x.value != y.value { return false }
            return true
        case let (.array(a), .array(b)):
            return a == b
        case let (.string(a), .string(b)):
            return a == b
        case let (.number(a), .number(b)):
            if let da = Double(a), let db = Double(b) { return da == db }
            return a == b
        case let (.bool(a), .bool(b)):
            return a == b
        case (.null, .null):
            return true
        default:
            return false
        }
    }

    var typeName: String {
        switch self {
        case .object: "object"
        case .array: "array"
        case .string: "string"
        case .number: "number"
        case .bool: "boolean"
        case .null: "null"
        }
    }

    /// A short, single-line preview suitable for tree rows and diff summaries.
    var preview: String {
        switch self {
        case let .object(pairs): "{ \(pairs.count) \(pairs.count == 1 ? "key" : "keys") }"
        case let .array(items): "[ \(items.count) \(items.count == 1 ? "item" : "items") ]"
        case let .string(s): "\"\(s.count > 60 ? String(s.prefix(60)) + "…" : s)\""
        case let .number(n): n
        case let .bool(b): b ? "true" : "false"
        case .null: "null"
        }
    }
}
