import Foundation
import Combine
import Sparkle

final class UpdaterManager: ObservableObject {
    let updaterController: SPUStandardUpdaterController
    @Published var canCheckForUpdates = false

    init() {
        updaterController = SPUStandardUpdaterController(
            startingUpdater: true,
            updaterDelegate: nil,
            userDriverDelegate: nil
        )
        // canCheckForUpdates is KVO-observable but not @Published; mirror it so
        // the menu item enables/disables as Sparkle's state changes.
        updaterController.updater.publisher(for: \.canCheckForUpdates)
            .assign(to: &$canCheckForUpdates)
    }

    var updater: SPUUpdater {
        updaterController.updater
    }

    func checkForUpdates() {
        updaterController.checkForUpdates(nil)
    }
}
