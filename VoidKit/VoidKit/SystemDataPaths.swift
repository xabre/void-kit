import Foundation

enum SafetyLevel {
    case safe
    case caution
    case unsafe

    var label: String {
        switch self {
        case .safe: return "Safe to Delete"
        case .caution: return "Review Before Deleting"
        case .unsafe: return "Do Not Delete"
        }
    }
}

struct SystemDataLocation {
    let path: String
    let requiresElevatedPermissions: Bool
    let safetyLevel: SafetyLevel
    let description: String
}

struct SystemDataPaths {
    static let knownSystemDataLocations: [SystemDataLocation] = [
        // User-level caches and logs
        SystemDataLocation(
            path: "~/Library/Caches",
            requiresElevatedPermissions: false,
            safetyLevel: .safe,
            description: "Temporary files cached by apps. Apps recreate these as needed."
        ),
        SystemDataLocation(
            path: "~/Library/Logs",
            requiresElevatedPermissions: false,
            safetyLevel: .safe,
            description: "Diagnostic logs. Safe to remove; new logs created automatically."
        ),

        // Application Support
        SystemDataLocation(
            path: "~/Library/Application Support",
            requiresElevatedPermissions: false,
            safetyLevel: .caution,
            description: "App settings, databases, and user data. Review individual items before deleting."
        ),

        // Safari and browser data (requires Full Disk Access)
        SystemDataLocation(
            path: "~/Library/Safari",
            requiresElevatedPermissions: true,
            safetyLevel: .unsafe,
            description: "Safari history, bookmarks, extensions. Deletion erases browsing data."
        ),
        SystemDataLocation(
            path: "~/Library/Cookies",
            requiresElevatedPermissions: false,
            safetyLevel: .caution,
            description: "Website cookies and sessions. Deleting signs you out of websites."
        ),

        // Mail and Messages (requires Full Disk Access)
        SystemDataLocation(
            path: "~/Library/Mail",
            requiresElevatedPermissions: true,
            safetyLevel: .unsafe,
            description: "Local email messages. Deletion may cause permanent email loss."
        ),
        SystemDataLocation(
            path: "~/Library/Messages",
            requiresElevatedPermissions: true,
            safetyLevel: .unsafe,
            description: "iMessage/SMS history and attachments. Deletion is irreversible."
        ),

        // Developer caches
        SystemDataLocation(
            path: "~/Library/Developer/Xcode/DerivedData",
            requiresElevatedPermissions: false,
            safetyLevel: .safe,
            description: "Xcode build artifacts. Deleting forces clean rebuild, no data loss."
        ),
        SystemDataLocation(
            path: "~/Library/Developer/CoreSimulator",
            requiresElevatedPermissions: false,
            safetyLevel: .caution,
            description: "Simulator devices and data. Removes simulator content but not Xcode."
        ),

        // System caches (requires admin / Full Disk Access)
        SystemDataLocation(
            path: "/Library/Caches",
            requiresElevatedPermissions: true,
            safetyLevel: .safe,
            description: "System-wide caches. System and apps regenerate these."
        ),
        SystemDataLocation(
            path: "/System/Library/Caches",
            requiresElevatedPermissions: true,
            safetyLevel: .caution,
            description: "Core macOS caches. Generally safe but may need reboot."
        ),

        // System logs (requires admin / Full Disk Access)
        SystemDataLocation(
            path: "/private/var/log",
            requiresElevatedPermissions: true,
            safetyLevel: .safe,
            description: "System diagnostic logs. System recreates log files automatically."
        ),

        // Temporary files (requires admin / Full Disk Access)
        SystemDataLocation(
            path: "/private/var/tmp",
            requiresElevatedPermissions: true,
            safetyLevel: .safe,
            description: "System temp files. Safe to remove; recreated as needed."
        ),
        SystemDataLocation(
            path: "/private/var/folders",
            requiresElevatedPermissions: true,
            safetyLevel: .caution,
            description: "Per-user temp/cache dirs. Active apps could be disrupted."
        ),

        // Time Machine local snapshots
        SystemDataLocation(
            path: "/.MobileBackups.trash",
            requiresElevatedPermissions: true,
            safetyLevel: .safe,
            description: "Deleted Time Machine snapshots. Safe to remove."
        ),

        SystemDataLocation(
            path: "~/.local/share",
            requiresElevatedPermissions: false,
            safetyLevel: .caution,
            description: "Data for CLI tools (Fish, VS Code Server). Check before deleting."
        ),

        // Virtual memory and sleep image
        SystemDataLocation(
            path: "/private/var/vm",
            requiresElevatedPermissions: true,
            safetyLevel: .unsafe,
            description: "Swap files and sleep image (size = RAM). Managed by the kernel."
        ),

        // iOS/iPadOS device backups
        SystemDataLocation(
            path: "~/Library/Application Support/MobileSync/Backup",
            requiresElevatedPermissions: false,
            safetyLevel: .caution,
            description: "iPhone/iPad local backups. Old backups for devices you no longer own can be deleted."
        ),

        // Group Containers (shared app data)
        SystemDataLocation(
            path: "~/Library/Group Containers",
            requiresElevatedPermissions: false,
            safetyLevel: .caution,
            description: "Shared data between related apps (Office, Adobe, etc.). Orphaned data is safe to remove."
        ),

        // Spotlight index
        SystemDataLocation(
            path: "/.Spotlight-V100",
            requiresElevatedPermissions: true,
            safetyLevel: .safe,
            description: "Spotlight search index. Deleting forces a rebuild; no data loss."
        ),

        // Xcode iOS DeviceSupport (debug symbols)
        SystemDataLocation(
            path: "~/Library/Developer/Xcode/iOS DeviceSupport",
            requiresElevatedPermissions: false,
            safetyLevel: .safe,
            description: "Debug symbols for connected iOS devices. Xcode re-downloads when needed."
        ),

        // Xcode Archives
        SystemDataLocation(
            path: "~/Library/Developer/Xcode/Archives",
            requiresElevatedPermissions: false,
            safetyLevel: .caution,
            description: "App build archives. Only delete if you don't need to re-submit old builds."
        ),

        // Homebrew (Apple Silicon)
        SystemDataLocation(
            path: "/opt/homebrew",
            requiresElevatedPermissions: false,
            safetyLevel: .caution,
            description: "Homebrew packages and caches. Run 'brew cleanup' to remove old versions safely."
        ),

        // System databases
        SystemDataLocation(
            path: "/private/var/db",
            requiresElevatedPermissions: true,
            safetyLevel: .unsafe,
            description: "System databases (Spotlight, APFS metadata, dyld cache). Do not delete."
        ),

        // Package manager caches
        SystemDataLocation(
            path: "~/.npm",
            requiresElevatedPermissions: false,
            safetyLevel: .safe,
            description: "npm package cache. Re-downloaded on next install."
        ),
        SystemDataLocation(
            path: "~/.gradle",
            requiresElevatedPermissions: false,
            safetyLevel: .safe,
            description: "Gradle build cache. Re-downloaded on next build."
        ),
        SystemDataLocation(
            path: "~/Library/Caches/CocoaPods",
            requiresElevatedPermissions: false,
            safetyLevel: .safe,
            description: "CocoaPods spec and download cache. Re-downloaded on next pod install."
        ),

        // Docker Desktop data
        SystemDataLocation(
            path: "~/Library/Containers/com.docker.docker",
            requiresElevatedPermissions: false,
            safetyLevel: .caution,
            description: "Docker Desktop disk image and data. Deleting destroys all containers and images."
        ),

        // Saved Application State
        SystemDataLocation(
            path: "~/Library/Saved Application State",
            requiresElevatedPermissions: false,
            safetyLevel: .safe,
            description: "Window positions and state saved by apps. Recreated on next launch."
        ),

        // WebKit and browser data
        SystemDataLocation(
            path: "~/Library/WebKit",
            requiresElevatedPermissions: false,
            safetyLevel: .caution,
            description: "WebKit browsing data and local storage. Deleting clears web app data."
        ),

        // Preferences
        SystemDataLocation(
            path: "~/Library/Preferences",
            requiresElevatedPermissions: false,
            safetyLevel: .caution,
            description: "App preference files (.plist). Deleting resets apps to defaults."
        ),
    ]

    static func expandPath(_ path: String) -> String {
        return NSString(string: path).expandingTildeInPath
    }
}
