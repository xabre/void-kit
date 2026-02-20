import Foundation

struct SystemDataLocation {
    let path: String
    let requiresElevatedPermissions: Bool
}

struct SystemDataPaths {
    static let knownSystemDataLocations: [SystemDataLocation] = [
        // User-level caches and logs
        SystemDataLocation(path: "~/Library/Caches", requiresElevatedPermissions: false),
        SystemDataLocation(path: "~/Library/Logs", requiresElevatedPermissions: false),

        // Application Support
        SystemDataLocation(path: "~/Library/Application Support", requiresElevatedPermissions: false),

        // Safari and browser data (requires Full Disk Access)
        SystemDataLocation(path: "~/Library/Safari", requiresElevatedPermissions: true),
        SystemDataLocation(path: "~/Library/Cookies", requiresElevatedPermissions: false),

        // Mail and Messages (requires Full Disk Access)
        SystemDataLocation(path: "~/Library/Mail", requiresElevatedPermissions: true),
        SystemDataLocation(path: "~/Library/Messages", requiresElevatedPermissions: true),

        // Developer caches
        SystemDataLocation(path: "~/Library/Developer/Xcode/DerivedData", requiresElevatedPermissions: false),
        SystemDataLocation(path: "~/Library/Developer/CoreSimulator", requiresElevatedPermissions: false),

        // System caches (requires admin / Full Disk Access)
        SystemDataLocation(path: "/Library/Caches", requiresElevatedPermissions: true),
        SystemDataLocation(path: "/System/Library/Caches", requiresElevatedPermissions: true),

        // System logs (requires admin / Full Disk Access)
        SystemDataLocation(path: "/private/var/log", requiresElevatedPermissions: true),

        // Temporary files (requires admin / Full Disk Access)
        SystemDataLocation(path: "/private/var/tmp", requiresElevatedPermissions: true),
        SystemDataLocation(path: "/private/var/folders", requiresElevatedPermissions: true),

        // Time Machine local snapshots
        SystemDataLocation(path: "/.MobileBackups.trash", requiresElevatedPermissions: true),

        SystemDataLocation(path: "~/.local/share", requiresElevatedPermissions: false),
    ]

    static func expandPath(_ path: String) -> String {
        return NSString(string: path).expandingTildeInPath
    }
}
