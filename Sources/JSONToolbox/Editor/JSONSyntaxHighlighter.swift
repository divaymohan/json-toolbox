import AppKit

/// A fast single-pass JSON syntax highlighter that colors an `NSTextStorage` in place.
///
/// Works directly on UTF-16 code units so it never allocates per-character; JSON structure is
/// pure ASCII, and non-ASCII bytes only appear inside strings, which are scanned as a unit.
enum JSONSyntaxHighlighter {
    static let font = NSFont.monospacedSystemFont(ofSize: 13, weight: .regular)

    static func highlight(_ storage: NSTextStorage) {
        let text = storage.string as NSString
        let n = text.length

        storage.beginEditing()
        storage.setAttributes([.font: font, .foregroundColor: Palette.editorText],
                              range: NSRange(location: 0, length: n))

        var i = 0
        while i < n {
            let c = text.character(at: i)
            switch c {
            case 0x22: // opening quote of a string
                var j = i + 1
                while j < n {
                    let cj = text.character(at: j)
                    if cj == 0x5C { j += 2; continue }   // backslash escape
                    if cj == 0x22 { j += 1; break }      // closing quote
                    j += 1
                }
                let end = min(j, n)
                // A string is a key if the next non-whitespace character is ':'.
                var k = end
                while k < n, isWhitespace(text.character(at: k)) { k += 1 }
                let isKey = k < n && text.character(at: k) == 0x3A
                color(storage, from: i, to: end, isKey ? Palette.key : Palette.string)
                i = end
            case 0x2D, 0x30...0x39: // '-' or a digit
                var j = i + 1
                while j < n, isNumberByte(text.character(at: j)) { j += 1 }
                color(storage, from: i, to: j, Palette.number)
                i = j
            case 0x74, 0x66, 0x6E: // 't', 'f', 'n' — potential literal
                var j = i
                while j < n, isAlpha(text.character(at: j)) { j += 1 }
                let word = text.substring(with: NSRange(location: i, length: j - i))
                if word == "true" || word == "false" {
                    color(storage, from: i, to: j, Palette.bool)
                } else if word == "null" {
                    color(storage, from: i, to: j, Palette.null)
                }
                i = max(j, i + 1)
            case 0x7B, 0x7D, 0x5B, 0x5D, 0x2C, 0x3A: // { } [ ] , :
                color(storage, from: i, to: i + 1, Palette.punctuation)
                i += 1
            default:
                i += 1
            }
        }
        storage.endEditing()
    }

    private static func color(_ storage: NSTextStorage, from: Int, to: Int, _ nsColor: NSColor) {
        guard to > from else { return }
        storage.addAttribute(.foregroundColor, value: nsColor, range: NSRange(location: from, length: to - from))
    }

    private static func isWhitespace(_ c: UInt16) -> Bool {
        c == 0x20 || c == 0x09 || c == 0x0A || c == 0x0D
    }
    private static func isNumberByte(_ c: UInt16) -> Bool {
        (c >= 0x30 && c <= 0x39) || c == 0x2E || c == 0x65 || c == 0x45 || c == 0x2B || c == 0x2D
    }
    private static func isAlpha(_ c: UInt16) -> Bool {
        (c >= 0x61 && c <= 0x7A) || (c >= 0x41 && c <= 0x5A)
    }
}
