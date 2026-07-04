import SwiftUI

/// Side-by-side structural comparison of two JSON documents.
struct CompareView: View {
    @EnvironmentObject var state: AppState
    @State private var entries: [JSONDiffEntry] = []
    @State private var parseError: String?

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            HSplitView {
                editorColumn(title: "A · Original", text: $state.leftText)
                editorColumn(title: "B · Modified", text: $state.rightText)
            }
            Divider()
            results
                .frame(minHeight: 140, idealHeight: 200)
        }
        .onAppear(perform: compare)
        .onChange(of: state.leftText) { _ in compare() }
        .onChange(of: state.rightText) { _ in compare() }
    }

    private var header: some View {
        HStack {
            Text("Compare").font(.headline)
            Spacer()
            summaryBadges
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    private var summaryBadges: some View {
        HStack(spacing: 10) {
            if parseError == nil {
                badge(count: entries.filter { $0.kind == .added }.count, kind: .added)
                badge(count: entries.filter { $0.kind == .removed }.count, kind: .removed)
                badge(count: entries.filter { $0.kind == .changed }.count, kind: .changed)
            }
        }
        .font(.callout)
    }

    private func badge(count: Int, kind: JSONDiffKind) -> some View {
        Label("\(count)", systemImage: kind.symbol)
            .foregroundStyle(kind.color)
    }

    private func editorColumn(title: String, text: Binding<String>) -> some View {
        VStack(spacing: 0) {
            Text(title)
                .font(.caption).bold()
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
            Divider()
            CodeEditor(text: text)
        }
        .frame(minWidth: 240)
    }

    @ViewBuilder
    private var results: some View {
        if let parseError {
            HStack(spacing: 6) {
                Image(systemName: "xmark.octagon.fill").foregroundStyle(.red)
                Text(parseError).foregroundStyle(.red)
                Spacer()
            }
            .padding(12)
        } else if entries.isEmpty {
            HStack(spacing: 6) {
                Image(systemName: "equal.circle.fill").foregroundStyle(.green)
                Text("The two documents are structurally identical.").foregroundStyle(.secondary)
                Spacer()
            }
            .padding(12)
        } else {
            List(entries) { entry in
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: entry.kind.symbol).foregroundStyle(entry.kind.color)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(entry.path).font(.system(.body, design: .monospaced))
                        HStack(spacing: 6) {
                            if let left = entry.left {
                                Text(left).foregroundStyle(.red).strikethrough(entry.kind == .changed)
                            }
                            if entry.kind == .changed {
                                Image(systemName: "arrow.right").font(.caption2).foregroundStyle(.secondary)
                            }
                            if let right = entry.right {
                                Text(right).foregroundStyle(.green)
                            }
                        }
                        .font(.system(.caption, design: .monospaced))
                    }
                }
                .padding(.vertical, 2)
            }
        }
    }

    private func compare() {
        let a = JSONParser.parse(state.leftText)
        let b = JSONParser.parse(state.rightText)
        switch (a, b) {
        case let (.failure(e), _):
            parseError = "A is invalid — line \(e.line):\(e.column): \(e.message)"
            entries = []
        case let (_, .failure(e)):
            parseError = "B is invalid — line \(e.line):\(e.column): \(e.message)"
            entries = []
        case let (.success(av), .success(bv)):
            parseError = nil
            entries = JSONDiff.diff(av, bv)
        }
    }
}
