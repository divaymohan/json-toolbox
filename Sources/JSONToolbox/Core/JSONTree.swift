import Foundation

/// A node in the collapsible tree view. Leaf values have `children == nil` so that
/// `OutlineGroup` does not draw a disclosure triangle for them.
struct JSONNode: Identifiable {
    let id = UUID()
    let label: String
    let value: JSONValue
    let children: [JSONNode]?

    var typeName: String { value.typeName }
    var isLeaf: Bool { children == nil }

    /// Preview shown on the right of a row (empty for containers, whose child count is
    /// already implied by expansion).
    var preview: String {
        switch value {
        case .object, .array: value.preview
        default: value.preview
        }
    }
}

enum JSONTreeBuilder {
    static func build(_ value: JSONValue, label: String) -> JSONNode {
        switch value {
        case let .object(pairs):
            return JSONNode(label: label, value: value, children: pairs.map { build($0.value, label: $0.key) })
        case let .array(items):
            return JSONNode(label: label, value: value, children: items.enumerated().map { build($0.element, label: "[\($0.offset)]") })
        default:
            return JSONNode(label: label, value: value, children: nil)
        }
    }
}
