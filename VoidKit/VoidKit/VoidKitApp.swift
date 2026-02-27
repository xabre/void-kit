import SwiftUI

@main
struct VoidKitApp: App {
    @StateObject private var deletionManager = DeletionManager()
    @StateObject private var updaterManager = UpdaterManager()

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
            CommandGroup(after: .appInfo) {
                CheckForUpdatesButton(updaterManager: updaterManager)
            }
        }

        Window("About Void Kit", id: "about") {
            AboutView()
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        .defaultPosition(.center)

        Settings {
            SettingsView(updaterManager: updaterManager)
        }
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

private struct CheckForUpdatesButton: View {
    @ObservedObject var updaterManager: UpdaterManager

    var body: some View {
        Button("Check for Updates…") {
            updaterManager.checkForUpdates()
        }
        .disabled(!updaterManager.updater.canCheckForUpdates)
    }
}
