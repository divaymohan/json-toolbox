import SwiftUI

@main
struct JSONToolboxApp: App {
    @StateObject private var state = AppState()
    @StateObject private var history = HistoryStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(state)
                .environmentObject(history)
                .frame(minWidth: 960, minHeight: 620)
        }
        .commands { SidebarCommands() }
    }
}
