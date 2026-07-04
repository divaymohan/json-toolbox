import Foundation

/// One saved document in the Format tab's history.
struct HistoryEntry: Identifiable, Codable, Equatable {
    let id: UUID
    var date: Date
    var text: String

    init(id: UUID = UUID(), date: Date, text: String) {
        self.id = id
        self.date = date
        self.text = text
    }

    var byteCount: Int { text.utf8.count }

    /// First non-empty line, trimmed, for a one-line row preview.
    var preview: String {
        let firstLine = text.split(whereSeparator: \.isNewline).first.map(String.init) ?? text
        let trimmed = firstLine.trimmingCharacters(in: .whitespaces)
        return trimmed.count > 90 ? String(trimmed.prefix(90)) + "…" : trimmed
    }
}

/// Persistent, newest-first history of JSON documents entered in the Format tab.
///
/// Stored as JSON at `~/Library/Application Support/JSONToolbox/history.json`, so it survives
/// relaunches and is kept until the user deletes entries explicitly.
final class HistoryStore: ObservableObject {
    @Published private(set) var entries: [HistoryEntry] = []

    private let fileURL: URL

    init() {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        let directory = base.appendingPathComponent("JSONToolbox", isDirectory: true)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        fileURL = directory.appendingPathComponent("history.json")
        load()
    }

    /// Adds a snapshot. Empty text is ignored; identical text is de-duplicated by moving the
    /// existing entry to the top and refreshing its date.
    func add(_ rawText: String, date: Date = Date()) {
        let text = rawText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }

        if let index = entries.firstIndex(where: { $0.text == text }) {
            var existing = entries.remove(at: index)
            existing.date = date
            entries.insert(existing, at: 0)
        } else {
            entries.insert(HistoryEntry(date: date, text: text), at: 0)
        }
        save()
    }

    func delete(_ entry: HistoryEntry) {
        entries.removeAll { $0.id == entry.id }
        save()
    }

    func clear() {
        entries.removeAll()
        save()
    }

    // MARK: - Persistence

    private func load() {
        guard let data = try? Data(contentsOf: fileURL),
              let decoded = try? JSONDecoder().decode([HistoryEntry].self, from: data) else { return }
        entries = decoded
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(entries) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }
}
