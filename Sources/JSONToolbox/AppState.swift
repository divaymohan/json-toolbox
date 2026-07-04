import SwiftUI

enum IndentOption: String, CaseIterable, Identifiable {
    case spaces2 = "2 spaces"
    case spaces4 = "4 spaces"
    case tab = "Tab"

    var id: String { rawValue }
    var string: String {
        switch self {
        case .spaces2: "  "
        case .spaces4: "    "
        case .tab: "\t"
        }
    }
}

/// Text buffers and formatting options shared across tabs so switching modes keeps content.
final class AppState: ObservableObject {
    @Published var mode: Mode = .format

    @Published var formatText: String = Sample.pretty
    @Published var leftText: String = Sample.left
    @Published var rightText: String = Sample.right
    @Published var treeText: String = Sample.pretty

    @Published var indent: IndentOption = .spaces2
    @Published var sortKeys: Bool = false

    /// Copies the current Format text into the Tree tab and switches to it.
    func openInTree() {
        treeText = formatText
        mode = .tree
    }
}
