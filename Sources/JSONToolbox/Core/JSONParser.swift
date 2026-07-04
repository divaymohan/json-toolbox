import Foundation

/// A parse failure with a human-readable message and 1-based source location.
struct JSONParseError: Error, Equatable {
    let message: String
    let line: Int
    let column: Int
}

/// A small hand-written recursive-descent JSON parser.
///
/// It exists (rather than using `JSONSerialization`) to preserve object key order,
/// keep the raw text of numbers, and report precise error locations for the editor.
struct JSONParser {
    private let chars: [Character]
    private var pos = 0

    private init(_ text: String) { chars = Array(text) }

    static func parse(_ text: String) -> Result<JSONValue, JSONParseError> {
        var parser = JSONParser(text)
        do {
            parser.skipWhitespace()
            guard parser.pos < parser.chars.count else {
                throw parser.error("Empty input")
            }
            let value = try parser.parseValue()
            parser.skipWhitespace()
            if parser.pos < parser.chars.count {
                throw parser.error("Unexpected trailing character '\(parser.chars[parser.pos])'")
            }
            return .success(value)
        } catch let e as JSONParseError {
            return .failure(e)
        } catch {
            return .failure(JSONParseError(message: "\(error)", line: 1, column: 1))
        }
    }

    // MARK: - Cursor helpers

    private var current: Character? { pos < chars.count ? chars[pos] : nil }

    private mutating func skipWhitespace() {
        while let c = current, c == " " || c == "\n" || c == "\t" || c == "\r" { pos += 1 }
    }

    private func error(_ message: String) -> JSONParseError {
        var line = 1, column = 1
        var i = 0
        while i < pos && i < chars.count {
            if chars[i] == "\n" { line += 1; column = 1 } else { column += 1 }
            i += 1
        }
        return JSONParseError(message: message, line: line, column: column)
    }

    // MARK: - Grammar

    private mutating func parseValue() throws -> JSONValue {
        skipWhitespace()
        guard let c = current else { throw error("Unexpected end of input") }
        switch c {
        case "{": return try parseObject()
        case "[": return try parseArray()
        case "\"": return .string(try parseString())
        case "t", "f": return try parseBool()
        case "n": return try parseNull()
        default:
            if c == "-" || ("0"..."9").contains(c) { return try parseNumber() }
            throw error("Unexpected character '\(c)'")
        }
    }

    private mutating func parseObject() throws -> JSONValue {
        pos += 1 // consume '{'
        var pairs: [(key: String, value: JSONValue)] = []
        skipWhitespace()
        if current == "}" { pos += 1; return .object(pairs) }
        while true {
            skipWhitespace()
            guard current == "\"" else { throw error("Expected string key in object") }
            let key = try parseString()
            skipWhitespace()
            guard current == ":" else { throw error("Expected ':' after key \"\(key)\"") }
            pos += 1
            let value = try parseValue()
            pairs.append((key, value))
            skipWhitespace()
            if current == "," { pos += 1; continue }
            if current == "}" { pos += 1; break }
            throw error("Expected ',' or '}' in object")
        }
        return .object(pairs)
    }

    private mutating func parseArray() throws -> JSONValue {
        pos += 1 // consume '['
        var items: [JSONValue] = []
        skipWhitespace()
        if current == "]" { pos += 1; return .array(items) }
        while true {
            let value = try parseValue()
            items.append(value)
            skipWhitespace()
            if current == "," { pos += 1; continue }
            if current == "]" { pos += 1; break }
            throw error("Expected ',' or ']' in array")
        }
        return .array(items)
    }

    private mutating func parseString() throws -> String {
        pos += 1 // consume opening quote
        var result = ""
        while pos < chars.count {
            let c = chars[pos]
            if c == "\"" { pos += 1; return result }
            if c == "\\" {
                pos += 1
                guard pos < chars.count else { throw error("Unterminated escape sequence") }
                switch chars[pos] {
                case "\"": result.append("\"")
                case "\\": result.append("\\")
                case "/": result.append("/")
                case "n": result.append("\n")
                case "t": result.append("\t")
                case "r": result.append("\r")
                case "b": result.append("\u{08}")
                case "f": result.append("\u{0C}")
                case "u": result.unicodeScalars.append(try parseUnicodeEscape())
                default: throw error("Invalid escape '\\\(chars[pos])'")
                }
                pos += 1
            } else {
                result.append(c)
                pos += 1
            }
        }
        throw error("Unterminated string")
    }

    /// Parses a `\uXXXX` escape (with `pos` at the `u`), including UTF-16 surrogate pairs.
    /// Leaves `pos` on the final hex digit consumed.
    private mutating func parseUnicodeEscape() throws -> Unicode.Scalar {
        func hex4() throws -> UInt32 {
            var value: UInt32 = 0
            for _ in 0..<4 {
                pos += 1
                guard pos < chars.count, let d = chars[pos].hexDigitValue else {
                    throw error("Invalid \\u escape")
                }
                value = value * 16 + UInt32(d)
            }
            return value
        }
        let first = try hex4()
        if (0xD800...0xDBFF).contains(first) {
            guard pos + 2 < chars.count, chars[pos + 1] == "\\", chars[pos + 2] == "u" else {
                throw error("Expected low surrogate after high surrogate")
            }
            pos += 2 // move onto the second 'u'
            let second = try hex4()
            guard (0xDC00...0xDFFF).contains(second) else { throw error("Invalid low surrogate") }
            let combined = 0x10000 + ((first - 0xD800) << 10) + (second - 0xDC00)
            guard let scalar = Unicode.Scalar(combined) else { throw error("Invalid surrogate pair") }
            return scalar
        }
        guard let scalar = Unicode.Scalar(first) else { throw error("Invalid unicode scalar") }
        return scalar
    }

    private mutating func parseNumber() throws -> JSONValue {
        let start = pos
        if current == "-" { pos += 1 }
        while let c = current, ("0"..."9").contains(c) { pos += 1 }
        if current == "." {
            pos += 1
            while let c = current, ("0"..."9").contains(c) { pos += 1 }
        }
        if current == "e" || current == "E" {
            pos += 1
            if current == "+" || current == "-" { pos += 1 }
            while let c = current, ("0"..."9").contains(c) { pos += 1 }
        }
        let raw = String(chars[start..<pos])
        if raw.isEmpty || raw == "-" { throw error("Invalid number") }
        return .number(raw)
    }

    private mutating func parseBool() throws -> JSONValue {
        if match("true") { return .bool(true) }
        if match("false") { return .bool(false) }
        throw error("Invalid literal")
    }

    private mutating func parseNull() throws -> JSONValue {
        if match("null") { return .null }
        throw error("Invalid literal")
    }

    private mutating func match(_ word: String) -> Bool {
        let w = Array(word)
        guard pos + w.count <= chars.count else { return false }
        for i in 0..<w.count where chars[pos + i] != w[i] { return false }
        pos += w.count
        return true
    }
}
