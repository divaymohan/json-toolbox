import Foundation

/// Renders a `JSONValue` back to text, either pretty-printed or minified.
enum JSONFormatter {
    static func pretty(_ value: JSONValue, indent: String, sortKeys: Bool) -> String {
        var out = ""
        writePretty(value, indent: indent, level: 0, sortKeys: sortKeys, into: &out)
        return out
    }

    static func minify(_ value: JSONValue, sortKeys: Bool = false) -> String {
        var out = ""
        writeMinified(value, sortKeys: sortKeys, into: &out)
        return out
    }

    // MARK: - Pretty

    private static func writePretty(_ value: JSONValue, indent: String, level: Int, sortKeys: Bool, into out: inout String) {
        switch value {
        case let .object(pairs):
            if pairs.isEmpty { out += "{}"; return }
            let items = sortKeys ? pairs.sorted { $0.key < $1.key } : pairs
            let pad = String(repeating: indent, count: level + 1)
            out += "{\n"
            for (i, pair) in items.enumerated() {
                out += pad + encodeString(pair.key) + ": "
                writePretty(pair.value, indent: indent, level: level + 1, sortKeys: sortKeys, into: &out)
                out += (i < items.count - 1 ? "," : "") + "\n"
            }
            out += String(repeating: indent, count: level) + "}"
        case let .array(arr):
            if arr.isEmpty { out += "[]"; return }
            let pad = String(repeating: indent, count: level + 1)
            out += "[\n"
            for (i, item) in arr.enumerated() {
                out += pad
                writePretty(item, indent: indent, level: level + 1, sortKeys: sortKeys, into: &out)
                out += (i < arr.count - 1 ? "," : "") + "\n"
            }
            out += String(repeating: indent, count: level) + "]"
        case let .string(s): out += encodeString(s)
        case let .number(n): out += n
        case let .bool(b): out += b ? "true" : "false"
        case .null: out += "null"
        }
    }

    // MARK: - Minified

    private static func writeMinified(_ value: JSONValue, sortKeys: Bool, into out: inout String) {
        switch value {
        case let .object(pairs):
            let items = sortKeys ? pairs.sorted { $0.key < $1.key } : pairs
            out += "{"
            for (i, pair) in items.enumerated() {
                out += encodeString(pair.key) + ":"
                writeMinified(pair.value, sortKeys: sortKeys, into: &out)
                if i < items.count - 1 { out += "," }
            }
            out += "}"
        case let .array(arr):
            out += "["
            for (i, item) in arr.enumerated() {
                writeMinified(item, sortKeys: sortKeys, into: &out)
                if i < arr.count - 1 { out += "," }
            }
            out += "]"
        case let .string(s): out += encodeString(s)
        case let .number(n): out += n
        case let .bool(b): out += b ? "true" : "false"
        case .null: out += "null"
        }
    }

    // MARK: - String escaping

    static func encodeString(_ s: String) -> String {
        var out = "\""
        for scalar in s.unicodeScalars {
            switch scalar {
            case "\"": out += "\\\""
            case "\\": out += "\\\\"
            case "\n": out += "\\n"
            case "\t": out += "\\t"
            case "\r": out += "\\r"
            case "\u{08}": out += "\\b"
            case "\u{0C}": out += "\\f"
            default:
                if scalar.value < 0x20 {
                    out += String(format: "\\u%04x", scalar.value)
                } else {
                    out.unicodeScalars.append(scalar)
                }
            }
        }
        out += "\""
        return out
    }
}
