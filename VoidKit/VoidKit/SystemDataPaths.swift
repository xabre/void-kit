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
            safetyLevel: .unsafe,
            description: "App settings, databases, and user data. Deletion may cause data loss."
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
    ]

    static func expandPath(_ path: String) -> String {
        return NSString(string: path).expandingTildeInPath
    }
}
