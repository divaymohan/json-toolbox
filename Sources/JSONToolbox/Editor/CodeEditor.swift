import SwiftUI
import AppKit

/// A SwiftUI wrapper around `NSTextView` providing a monospaced, syntax-highlighted JSON editor
/// with the native ⌘F find bar.
///
/// It intentionally uses `NSTextView.scrollableTextView()` and leaves the text system otherwise
/// stock: on macOS 26 a custom TextKit stack / ruler stops glyphs from rendering.
struct CodeEditor: NSViewRepresentable {
    @Binding var text: String
    var isEditable: Bool = true

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSTextView.scrollableTextView()
        scrollView.borderType = .noBorder
        scrollView.drawsBackground = true
        scrollView.backgroundColor = Palette.editorBackground

        let textView = scrollView.documentView as! NSTextView
        textView.delegate = context.coordinator
        textView.isEditable = isEditable
        textView.isRichText = false
        textView.allowsUndo = true
        textView.font = JSONSyntaxHighlighter.font
        textView.drawsBackground = true
        textView.backgroundColor = Palette.editorBackground
        textView.textColor = Palette.editorText
        textView.insertionPointColor = Palette.caret
        textView.selectedTextAttributes = [.backgroundColor: Palette.selection]
        textView.textContainerInset = NSSize(width: 8, height: 10)
        textView.usesFindBar = true

        // Turn off "smart" substitutions that would corrupt JSON.
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false
        textView.isAutomaticTextReplacementEnabled = false
        textView.isAutomaticSpellingCorrectionEnabled = false
        textView.isAutomaticDataDetectionEnabled = false
        textView.isContinuousSpellCheckingEnabled = false
        textView.isGrammarCheckingEnabled = false

        textView.string = text
        context.coordinator.textView = textView
        if let storage = textView.textStorage { JSONSyntaxHighlighter.highlight(storage) }
        return scrollView
    }

    func updateNSView(_ nsView: NSScrollView, context: Context) {
        guard let textView = nsView.documentView as? NSTextView else { return }
        textView.isEditable = isEditable
        // Only replace when an external change (e.g. Beautify) diverges from the buffer, to
        // avoid disturbing the caret while the user types.
        if textView.string != text {
            textView.string = text
            if let storage = textView.textStorage { JSONSyntaxHighlighter.highlight(storage) }
        }
    }

    final class Coordinator: NSObject, NSTextViewDelegate {
        let parent: CodeEditor
        weak var textView: NSTextView?

        init(_ parent: CodeEditor) { self.parent = parent }

        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            if let storage = textView.textStorage { JSONSyntaxHighlighter.highlight(storage) }
            parent.text = textView.string
        }
    }
}
