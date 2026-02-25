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
            CommandGroup(replacing: .appInfo) {
                AboutMenuButton()
            }
        }

        Window("About Void Kit", id: "about") {
            AboutView()
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        .defaultPosition(.center)
    }
}

private struct AboutMenuButton: View {
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        Button("About Void Kit") {
            openWindow(id: "about")
        }
    }
}
