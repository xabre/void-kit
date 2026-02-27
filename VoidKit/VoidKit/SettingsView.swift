import SwiftUI
import Sparkle

struct SettingsView: View {
    @ObservedObject var updaterManager: UpdaterManager

    @State private var automaticallyChecksForUpdates: Bool = true

    var body: some View {
        Form {
            Toggle("Automatically check for updates", isOn: $automaticallyChecksForUpdates)
                .onChange(of: automaticallyChecksForUpdates) { newValue in
                    updaterManager.updater.automaticallyChecksForUpdates = newValue
                }
        }
        .padding(20)
        .frame(width: 350)
        .onAppear {
            automaticallyChecksForUpdates = updaterManager.updater.automaticallyChecksForUpdates
        }
    }
}
