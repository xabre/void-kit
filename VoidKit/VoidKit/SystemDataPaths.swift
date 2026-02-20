import Foundation

struct SystemDataPaths {
    static let knownSystemDataLocations: [String] = [
        // User-level caches and logs
        "~/Library/Caches",
        "~/Library/Logs",
        
        // Application Support
        "~/Library/Application Support",
        
        // Safari and browser data
        "~/Library/Safari",
        "~/Library/Cookies",
        
        // Mail and Messages
        "~/Library/Mail",
        "~/Library/Messages",
        
        // Developer caches
        "~/Library/Developer/Xcode/DerivedData",
        "~/Library/Developer/CoreSimulator",
        
        // System caches (requires admin access)
        "/Library/Caches",
        "/System/Library/Caches",
        
        // System logs
        "/private/var/log",
        
        // Temporary files
        "/private/var/tmp",
        "/private/var/folders",
        
        // Time Machine local snapshots
        "/.MobileBackups.trash"
    ]
    
    static func expandPath(_ path: String) -> String {
        return NSString(string: path).expandingTildeInPath
    }
}
