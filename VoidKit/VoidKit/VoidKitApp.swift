import SwiftUI

@main
struct VoidKitApp: App {
    @StateObject private var deletionManager = DeletionManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(deletionManager)
        }
        .windowStyle(.hiddenTitleBar)
        .commands {
            CommandGroup(replacing: .newItem) { }
        }
    }
}
