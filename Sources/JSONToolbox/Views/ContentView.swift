import SwiftUI
import AppKit

enum Mode: String, CaseIterable, Identifiable, Hashable {
    case format, compare, tree

    var id: String { rawValue }
    var title: String {
        switch self {
        case .format: "Format & Validate"
        case .compare: "Compare"
        case .tree: "Tree & Query"
        }
    }
    var icon: String {
        switch self {
        case .format: "wand.and.stars"
        case .compare: "arrow.left.arrow.right"
        case .tree: "list.bullet.indent"
        }
    }
}

enum AppAppearance: String, CaseIterable, Identifiable {
    case light, system, dark

    var id: String { rawValue }
    var title: String {
        switch self {
        case .light: "Light"
        case .system: "System"
        case .dark: "Dark"
        }
    }
    var nsAppearance: NSAppearance? {
        switch self {
        case .light: NSAppearance(named: .aqua)
        case .system: nil
        case .dark: NSAppearance(named: .darkAqua)
        }
    }
}

struct ContentView: View {
    @EnvironmentObject var state: AppState
    @AppStorage("appearance") private var appearanceRaw = AppAppearance.system.rawValue

    private var appearance: AppAppearance { AppAppearance(rawValue: appearanceRaw) ?? .system }

    /// Bridges the optional selection a `List` expects to the non-optional shared `state.mode`.
    private var selection: Binding<Mode?> {
        Binding(get: { state.mode }, set: { if let new = $0 { state.mode = new } })
    }

    var body: some View {
        NavigationSplitView {
            List(Mode.allCases, id: \.self, selection: selection) { item in
                Label(item.title, systemImage: item.icon)
            }
            .navigationSplitViewColumnWidth(min: 180, ideal: 200, max: 240)
            .navigationTitle("JSON Toolbox")
            .safeAreaInset(edge: .bottom) {
                Picker("Appearance", selection: $appearanceRaw) {
                    ForEach(AppAppearance.allCases) { Text($0.title).tag($0.rawValue) }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .padding(10)
            }
        } detail: {
            switch state.mode {
            case .format: FormatView()
            case .compare: CompareView()
            case .tree: TreeView()
            }
        }
        .onAppear(perform: applyAppearance)
        .onChange(of: appearanceRaw) { _ in applyAppearance() }
    }

    private func applyAppearance() {
        NSApp.appearance = appearance.nsAppearance
    }
}
