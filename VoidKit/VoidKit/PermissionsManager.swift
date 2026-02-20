import Foundation
import AppKit

class PermissionsManager: ObservableObject {
    @Published var hasFullDiskAccess: Bool = false

    init() {
        // Attempt to access a TCC-protected path so macOS registers this app in
        // System Settings → Privacy & Security → Full Disk Access.
        // The attempt itself — even when denied — is what triggers the list entry.
        registerWithTCC()
        checkPermissions()
    }

    func checkPermissions() {
        hasFullDiskAccess = detectFullDiskAccess()
    }

    // Enumerate ~/Library/Safari, a canonical TCC-protected directory.
    // On first run this call fails silently, but macOS records the attempt and
    // makes the app appear in the Full Disk Access list in System Settings.
    private func registerWithTCC() {
        let safariDir = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Safari")
        _ = try? FileManager.default.contentsOfDirectory(
            at: safariDir,
            includingPropertiesForKeys: nil
        )
    }

    // Detect Full Disk Access by attempting to read the user-level TCC database.
    // This file is only accessible when Full Disk Access has been granted.
    private func detectFullDiskAccess() -> Bool {
        let tccDB = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Application Support/com.apple.TCC/TCC.db")
        return FileManager.default.isReadableFile(atPath: tccDB.path)
    }

    func openFullDiskAccessSettings() {
        // Deep-link directly to the Full Disk Access pane in System Settings (macOS 13+)
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles") {
            NSWorkspace.shared.open(url)
        }
    }
}
