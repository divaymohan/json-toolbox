import SwiftUI

/// The History popover: restore, delete, or clear saved Format-tab documents.
struct HistoryView: View {
    @ObservedObject var history: HistoryStore
    let currentText: String
    var onRestore: (String) -> Void

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            if history.entries.isEmpty {
                emptyState
            } else {
                list
                Divider()
                footer
            }
        }
        .frame(width: 440)
    }

    private var header: some View {
        HStack {
            Label("History", systemImage: "clock.arrow.circlepath").font(.headline)
            Spacer()
            Button {
                history.add(currentText)
            } label: {
                Label("Save current", systemImage: "plus")
            }
            .disabled(currentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .padding(10)
    }

    private var emptyState: some View {
        VStack(spacing: 6) {
            Image(systemName: "clock").font(.title2).foregroundStyle(.secondary)
            Text("No history yet.").foregroundStyle(.secondary)
            Text("JSON you paste, open, or save shows up here.")
                .font(.caption).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
    }

    private var list: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(history.entries) { entry in
                    row(entry)
                    Divider()
                }
            }
        }
        .frame(maxHeight: 340)
    }

    private func row(_ entry: HistoryEntry) -> some View {
        Button {
            onRestore(entry.text)
        } label: {
            HStack(alignment: .top, spacing: 10) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(entry.preview)
                        .font(.system(.body, design: .monospaced))
                        .lineLimit(1)
                        .truncationMode(.middle)
                    HStack(spacing: 6) {
                        Text(entry.date.formatted(date: .abbreviated, time: .shortened))
                        Text("· \(entry.byteCount) bytes")
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
                Spacer(minLength: 8)
                Button {
                    history.delete(entry)
                } label: {
                    Image(systemName: "trash")
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
                .help("Delete this entry")
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var footer: some View {
        HStack {
            Text("\(history.entries.count) item\(history.entries.count == 1 ? "" : "s")")
                .font(.caption).foregroundStyle(.secondary)
            Spacer()
            Button(role: .destructive) {
                history.clear()
            } label: {
                Label("Clear All", systemImage: "trash")
            }
        }
        .padding(10)
    }
}
