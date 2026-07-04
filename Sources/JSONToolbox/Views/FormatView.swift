import SwiftUI
import AppKit
import UniformTypeIdentifiers

/// Beautify / minify / validate a single JSON document.
struct FormatView: View {
    @EnvironmentObject var state: AppState
    @EnvironmentObject var history: HistoryStore
    @State private var status: Status = .empty
    @State private var showHistory = false
    @State private var pasteMonitor: Any?

    private enum Status {
        case empty
        case valid(bytes: Int)
        case invalid(JSONParseError)
    }

    var body: some View {
        VStack(spacing: 0) {
            toolbar
            Divider()
            CodeEditor(text: $state.formatText)
                .onChange(of: state.formatText) { _ in validate() }
            Divider()
            statusBar
        }
        .onAppear {
            validate()
            installPasteMonitor()
        }
        .onDisappear(perform: removePasteMonitor)
    }

    // MARK: - Toolbar

    private var toolbar: some View {
        HStack(spacing: 8) {
            Button(action: beautify) { Label("Beautify", systemImage: "wand.and.stars") }
                .keyboardShortcut("b", modifiers: .command)
            Button(action: minify) { Label("Minify", systemImage: "arrow.down.right.and.arrow.up.left") }
                .keyboardShortcut("m", modifiers: .command)

            Divider().frame(height: 18)

            Picker("Indent", selection: $state.indent) {
                ForEach(IndentOption.allCases) { Text($0.rawValue).tag($0) }
            }
            .labelsHidden()
            .frame(width: 110)
            .onChange(of: state.indent) { _ in if case .valid = status { beautify() } }

            Toggle("Sort keys", isOn: $state.sortKeys)
                .toggleStyle(.checkbox)
                .onChange(of: state.sortKeys) { _ in if case .valid = status { beautify() } }

            Spacer()

            Button(action: openInTree) {
                Label("Open in Tree", systemImage: "list.bullet.indent")
            }
            .help("Send this JSON to the Tree & Query tab")

            Divider().frame(height: 18)

            Button { showHistory.toggle() } label: { Image(systemName: "clock.arrow.circlepath") }
                .help("History of pasted / opened JSON")
                .popover(isPresented: $showHistory, arrowEdge: .bottom) {
                    HistoryView(history: history, currentText: state.formatText) { text in
                        state.formatText = text
                        validate()
                        showHistory = false
                    }
                }

            Button(action: openFile) { Image(systemName: "folder") }
                .help("Open a .json file")
            Button(action: saveFile) { Image(systemName: "square.and.arrow.down") }
                .help("Save to a .json file")
            Button(action: copyAll) { Image(systemName: "doc.on.doc") }
                .help("Copy all")
            Button(action: { state.formatText = "" }) { Image(systemName: "trash") }
                .help("Clear")
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    // MARK: - Status bar

    private var statusBar: some View {
        HStack(spacing: 6) {
            switch status {
            case .empty:
                Image(systemName: "circle.dashed").foregroundStyle(.secondary)
                Text("Empty").foregroundStyle(.secondary)
            case let .valid(bytes):
                Image(systemName: "checkmark.seal.fill").foregroundStyle(.green)
                Text("Valid JSON").foregroundStyle(.green)
                Text("· \(bytes) bytes").foregroundStyle(.secondary)
            case let .invalid(error):
                Image(systemName: "xmark.octagon.fill").foregroundStyle(.red)
                Text("Line \(error.line):\(error.column) — \(error.message)").foregroundStyle(.red)
            }
            Spacer()
        }
        .font(.callout)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
    }

    // MARK: - Actions

    private func validate() {
        if state.formatText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            status = .empty
            return
        }
        switch JSONParser.parse(state.formatText) {
        case .success:
            status = .valid(bytes: state.formatText.utf8.count)
        case let .failure(error):
            status = .invalid(error)
        }
    }

    private func beautify() {
        guard case let .success(value) = JSONParser.parse(state.formatText) else { validate(); return }
        state.formatText = JSONFormatter.pretty(value, indent: state.indent.string, sortKeys: state.sortKeys)
        validate()
    }

    private func minify() {
        guard case let .success(value) = JSONParser.parse(state.formatText) else { validate(); return }
        state.formatText = JSONFormatter.minify(value, sortKeys: state.sortKeys)
        validate()
    }

    private func copyAll() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(state.formatText, forType: .string)
    }

    private func openInTree() {
        state.openInTree()
    }

    private func openFile() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.json, .text]
        panel.allowsMultipleSelection = false
        if panel.runModal() == .OK, let url = panel.url, let contents = try? String(contentsOf: url, encoding: .utf8) {
            state.formatText = contents
            history.add(contents)
            validate()
        }
    }

    // MARK: - Paste capture

    /// Snapshots the document into history right after a ⌘V paste while this tab is visible.
    private func installPasteMonitor() {
        guard pasteMonitor == nil else { return }
        pasteMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            if event.modifierFlags.contains(.command),
               event.charactersIgnoringModifiers?.lowercased() == "v" {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    history.add(state.formatText)
                }
            }
            return event
        }
    }

    private func removePasteMonitor() {
        if let monitor = pasteMonitor {
            NSEvent.removeMonitor(monitor)
            pasteMonitor = nil
        }
    }

    private func saveFile() {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.json]
        panel.nameFieldStringValue = "data.json"
        if panel.runModal() == .OK, let url = panel.url {
            try? state.formatText.write(to: url, atomically: true, encoding: .utf8)
        }
    }
}
