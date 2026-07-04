import AppKit
import SwiftUI

extension NSColor {
    convenience init(hex: UInt32) {
        let r = CGFloat((hex >> 16) & 0xFF) / 255
        let g = CGFloat((hex >> 8) & 0xFF) / 255
        let b = CGFloat(hex & 0xFF) / 255
        self.init(srgbRed: r, green: g, blue: b, alpha: 1)
    }

    /// A color that resolves differently in light vs dark appearance.
    static func themed(light: UInt32, dark: UInt32) -> NSColor {
        NSColor(name: nil) { appearance in
            let isDark = appearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua
            return NSColor(hex: isDark ? dark : light)
        }
    }
}

/// The editor color theme (a soft, VS Code-inspired palette). All colors adapt to light/dark.
enum Palette {
    // Editor chrome
    static let editorBackground = NSColor.themed(light: 0xFBFBFD, dark: 0x1E1F27)
    static let editorText       = NSColor.themed(light: 0x1D1D1F, dark: 0xE6E6EA)
    static let gutterBackground = NSColor.themed(light: 0xF1F1F5, dark: 0x191A21)
    static let gutterText       = NSColor.themed(light: 0xB4B4BC, dark: 0x565863)
    static let caret            = NSColor.themed(light: 0x0A69C7, dark: 0x6FB7FF)
    static let selection        = NSColor.themed(light: 0xCCE4FF, dark: 0x2E4A6B)

    // Syntax tokens
    static let key         = NSColor.themed(light: 0x0A69C7, dark: 0x6FB7FF)
    static let string      = NSColor.themed(light: 0x1A7F37, dark: 0x9ADE7B)
    static let number      = NSColor.themed(light: 0x9A34C7, dark: 0xD6A6FF)
    static let bool        = NSColor.themed(light: 0xB35900, dark: 0xFFB871)
    static let null        = NSColor.themed(light: 0x8A8A8E, dark: 0x8A8D96)
    static let punctuation = NSColor.themed(light: 0x86868B, dark: 0x8A8D96)
}

extension JSONDiffKind {
    var color: Color {
        switch self {
        case .added: .green
        case .removed: .red
        case .changed: .orange
        }
    }
    var symbol: String {
        switch self {
        case .added: "plus.circle.fill"
        case .removed: "minus.circle.fill"
        case .changed: "pencil.circle.fill"
        }
    }
}
