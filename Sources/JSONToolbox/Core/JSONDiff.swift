import Foundation

enum JSONDiffKind: String {
    case added = "Added"
    case removed = "Removed"
    case changed = "Changed"
}

struct JSONDiffEntry: Identifiable {
    let id = UUID()
    let path: String
    let kind: JSONDiffKind
    let left: String?
    let right: String?
}

/// A structural, path-based diff between two JSON documents.
///
/// Objects are compared by key (order-independent), arrays by index. Nested containers are
/// recursed into so that only the leaves that actually differ are reported.
enum JSONDiff {
    static func diff(_ a: JSONValue, _ b: JSONValue) -> [JSONDiffEntry] {
        var entries: [JSONDiffEntry] = []
        compare(path: "$", a: a, b: b, into: &entries)
        return entries
    }

    private static func compare(path: String, a: JSONValue, b: JSONValue, into entries: inout [JSONDiffEntry]) {
        switch (a, b) {
        case let (.object(ap), .object(bp)):
            let am = Dictionary(ap.map { ($0.key, $0.value) }, uniquingKeysWith: { first, _ in first })
            let bm = Dictionary(bp.map { ($0.key, $0.value) }, uniquingKeysWith: { first, _ in first })
            for key in orderedUnion(ap.map(\.key), bp.map(\.key)) {
                let childPath = "\(path).\(key)"
                switch (am[key], bm[key]) {
                case let (av?, bv?):
                    compare(path: childPath, a: av, b: bv, into: &entries)
                case let (nil, bv?):
                    entries.append(JSONDiffEntry(path: childPath, kind: .added, left: nil, right: bv.preview))
                case let (av?, nil):
                    entries.append(JSONDiffEntry(path: childPath, kind: .removed, left: av.preview, right: nil))
                case (nil, nil):
                    break
                }
            }
        case let (.array(aa), .array(ba)):
            for i in 0..<max(aa.count, ba.count) {
                let childPath = "\(path)[\(i)]"
                if i < aa.count && i < ba.count {
                    compare(path: childPath, a: aa[i], b: ba[i], into: &entries)
                } else if i < ba.count {
                    entries.append(JSONDiffEntry(path: childPath, kind: .added, left: nil, right: ba[i].preview))
                } else {
                    entries.append(JSONDiffEntry(path: childPath, kind: .removed, left: aa[i].preview, right: nil))
                }
            }
        default:
            if a != b {
                entries.append(JSONDiffEntry(path: path, kind: .changed, left: a.preview, right: b.preview))
            }
        }
    }

    private static func orderedUnion(_ a: [String], _ b: [String]) -> [String] {
        var seen = Set<String>()
        var result: [String] = []
        for key in a + b where seen.insert(key).inserted {
            result.append(key)
        }
        return result
    }
}
