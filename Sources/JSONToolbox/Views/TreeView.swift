import SwiftUI

/// Browse JSON as a collapsible tree, search keys/values, and evaluate path queries.
struct TreeView: View {
    @EnvironmentObject var state: AppState
    @State private var root: JSONNode?
    @State private var parseError: JSONParseError?

    @State private var searchText: String = ""
    @State private var matches: [JSONSearchMatch] = []

    @State private var query: String = "$"
    @State private var queryResult: String?
    @State private var queryError: String?

    var body: some View {
        HSplitView {
            VStack(spacing: 0) {
                columnHeader("Input")
                Divider()
                CodeEditor(text: $state.treeText)
                    .onChange(of: state.treeText) { _ in rebuild() }
            }
            .frame(minWidth: 240, maxWidth: .infinity)

            VStack(spacing: 0) {
                searchBar
                Divider()
                queryInput
                Divider()
                // Draggable divider: make the query result area taller/shorter as needed.
                VSplitView {
                    queryResultPane
                        .frame(minHeight: 44, idealHeight: 120, maxHeight: .infinity)
                    Group {
                        if searchText.trimmingCharacters(in: .whitespaces).isEmpty {
                            treeContent
                        } else {
                            searchResults
                        }
                    }
                    .frame(minHeight: 160, maxHeight: .infinity)
                    .layoutPriority(1)
                }
            }
            .frame(minWidth: 260, maxWidth: .infinity)
        }
        .onAppear {
            rebuild()
            runQuery()
        }
    }

    private func columnHeader(_ title: String) -> some View {
        Text(title)
            .font(.caption).bold()
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
    }

    // MARK: - Search

    private var searchBar: some View {
        HStack(spacing: 6) {
            Image(systemName: "magnifyingglass").foregroundStyle(.secondary)
            TextField("Search keys or values…", text: $searchText)
                .textFieldStyle(.roundedBorder)
                .onChange(of: searchText) { _ in runSearch() }
            if !searchText.isEmpty {
                Text("\(matches.count) match\(matches.count == 1 ? "" : "es")")
                    .font(.caption).foregroundStyle(.secondary)
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill").foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(10)
    }

    @ViewBuilder
    private var searchResults: some View {
        if matches.isEmpty {
            VStack(spacing: 6) {
                Image(systemName: "magnifyingglass").foregroundStyle(.secondary).font(.title2)
                Text("No keys or values match “\(searchText)”.").foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            List(matches) { match in
                Button {
                    query = match.path
                    runQuery()
                } label: {
                    matchRow(match)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func matchRow(_ match: JSONSearchMatch) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            VStack(alignment: .leading, spacing: 2) {
                Text(match.path)
                    .font(.system(.body, design: .monospaced))
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text(match.valuePreview)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            if match.keyMatch { tag("key", .blue).fixedSize() }
            if match.valueMatch { tag("value", .green).fixedSize() }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 2)
        .contentShape(Rectangle())
    }

    private func tag(_ text: String, _ color: Color) -> some View {
        Text(text)
            .font(.caption2)
            .padding(.horizontal, 5).padding(.vertical, 1)
            .background(color.opacity(0.18), in: Capsule())
            .foregroundStyle(color)
    }

    // MARK: - Path query

    private var queryInput: some View {
        HStack(spacing: 6) {
            Image(systemName: "curlybraces").foregroundStyle(.secondary)
            TextField("Path: $.author.name  or  features[0]", text: $query)
                .textFieldStyle(.roundedBorder)
                .font(.system(.body, design: .monospaced))
                .onSubmit(runQuery)
            Button("Go", action: runQuery)
        }
        .padding(10)
    }

    /// The path-query output, sized by the surrounding `VSplitView` so its height is draggable.
    private var queryResultPane: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Result")
                .font(.caption).bold()
                .foregroundStyle(.secondary)
                .padding(.horizontal, 10)
                .padding(.top, 6)
                .padding(.bottom, 4)
            ScrollView(.vertical) {
                HStack(spacing: 0) {
                    queryResultText
                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 10)
                .padding(.bottom, 8)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    @ViewBuilder
    private var queryResultText: some View {
        if let queryError {
            Text(queryError)
                .font(.caption)
                .foregroundStyle(.red)
        } else if let queryResult {
            Text(queryResult)
                .font(.system(.caption, design: .monospaced))
                .textSelection(.enabled)
        } else {
            Text("Run a path query above to see its value here.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private var treeContent: some View {
        if let root {
            // Show the document's top-level entries directly (expanded) rather than a single
            // collapsed "root" node.
            List {
                OutlineGroup(root.children ?? [root], id: \.id, children: \.children) { node in
                    row(node)
                }
            }
        } else if let parseError {
            VStack(spacing: 6) {
                Image(systemName: "xmark.octagon.fill").foregroundStyle(.red).font(.title2)
                Text("Line \(parseError.line):\(parseError.column)").bold()
                Text(parseError.message).foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            Text("Paste JSON on the left to explore it here.")
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private func row(_ node: JSONNode) -> some View {
        HStack(spacing: 8) {
            Text(node.label)
                .font(.system(.body, design: .monospaced))
                .foregroundStyle(node.isLeaf ? .primary : Color.accentColor)
                .lineLimit(1)
                .truncationMode(.tail)
            Text(node.typeName)
                .font(.caption2)
                .padding(.horizontal, 5).padding(.vertical, 1)
                .background(Color.secondary.opacity(0.15), in: Capsule())
                .foregroundStyle(.secondary)
                .fixedSize()
            Spacer(minLength: 8)
            Text(node.preview)
                .font(.system(.caption, design: .monospaced))
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .truncationMode(.tail)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 1)
    }

    // MARK: - Data

    private func rebuild() {
        switch JSONParser.parse(state.treeText) {
        case let .success(value):
            root = JSONTreeBuilder.build(value, label: "root")
            parseError = nil
        case let .failure(error):
            root = nil
            parseError = error
        }
        runSearch()
    }

    private func runSearch() {
        guard case let .success(value) = JSONParser.parse(state.treeText) else {
            matches = []
            return
        }
        matches = JSONSearch.search(value, term: searchText)
    }

    private func runQuery() {
        guard case let .success(value) = JSONParser.parse(state.treeText) else {
            queryResult = nil
            queryError = "Input is not valid JSON."
            return
        }
        switch JSONQuery.evaluate(query, on: value) {
        case let .value(result):
            queryError = nil
            queryResult = JSONFormatter.pretty(result, indent: "  ", sortKeys: false)
        case let .failure(message):
            queryResult = nil
            queryError = message
        }
    }
}
