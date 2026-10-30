import Foundation
import CryptoKit

extension Bundle {
    /// Resolved display name: CFBundleDisplayName → CFBundleName → filename.
    var displayName: String {
        object(forInfoDictionaryKey: "CFBundleDisplayName") as? String
            ?? object(forInfoDictionaryKey: "CFBundleName") as? String
            ?? bundleURL.deletingPathExtension().lastPathComponent
    }
}

enum FileUtilities {
    /// Subdirectories inside ~/Library that trigger TCC permission prompts
    /// (Music, Photos, Contacts, etc.) and are irrelevant to storage cleanup.
    private static let tccProtectedPaths: Set<String> = {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        return [
            // Media & Music – triggers "would like to access your Music" prompt
            "\(home)/Library/Application Support/com.apple.MediaLibrary",
            "\(home)/Library/Application Support/com.apple.avfoundation",
            "\(home)/Library/Application Support/com.apple.AMPLibraryAgent",
            "\(home)/Library/Application Support/com.apple.AMPArtworkAgent",
            "\(home)/Library/Application Support/com.apple.iTunesCloud",
            "\(home)/Library/Application Support/com.apple.Music",
            "\(home)/Music",
            // Contacts & Calendar
            "\(home)/Library/Application Support/AddressBook",
            "\(home)/Library/Calendars",
            "\(home)/Library/Contacts",
            // Home, Identity, Photos
            "\(home)/Library/HomeKit",
            "\(home)/Library/IdentityServices",
            "\(home)/Library/Photos",
            "\(home)/Pictures/Photos Library.photoslibrary",
            // Reminders, Sharing, Suggestions
            "\(home)/Library/Reminders",
            "\(home)/Library/Sharing",
            "\(home)/Library/Suggestions",
            // Group containers for Apple media apps
            "\(home)/Library/Group Containers/group.com.apple.music",
            "\(home)/Library/Group Containers/group.com.apple.podcasts",
        ]
    }()

    /// Check if a path is inside a TCC-protected directory.
    static func isTCCProtected(_ path: String) -> Bool {
        tccProtectedPaths.contains(where: { isPath(path, inside: $0) })
    }

    /// True if `path` equals `directory` or is nested inside it.
    /// Plain `hasPrefix` would also match siblings like "~/MusicApps" for "~/Music".
    static func isPath(_ path: String, inside directory: String) -> Bool {
        path == directory || path.hasPrefix(directory + "/")
    }

    /// Create a deterministic UUID from a path so the same item
    /// produces the same ID across re-scans and across tabs.
    static func stableID(forPath path: String) -> UUID {
        let hash = SHA256.hash(data: Data(path.utf8))
        let bytes = Array(hash)
        // Build a UUID from the first 16 bytes of the SHA-256 digest
        return UUID(uuid: (
            bytes[0], bytes[1], bytes[2], bytes[3],
            bytes[4], bytes[5], bytes[6], bytes[7],
            bytes[8], bytes[9], bytes[10], bytes[11],
            bytes[12], bytes[13], bytes[14], bytes[15]
        ))
    }

    /// Calculate the total allocated size of all files in a directory tree.
    /// Uses `totalFileAllocatedSizeKey` for accurate disk usage matching Finder.
    static func calculateDirectorySize(atPath path: String) -> Int64 {
        var totalSize: Int64 = 0

        guard let enumerator = FileManager.default.enumerator(
            at: URL(fileURLWithPath: path),
            includingPropertiesForKeys: [.totalFileAllocatedSizeKey, .isDirectoryKey],
            options: []
        ) else {
            return 0
        }

        for case let fileURL as URL in enumerator {
            // Skip TCC-protected directories to avoid unwanted permission prompts
            if isTCCProtected(fileURL.path) {
                enumerator.skipDescendants()
                continue
            }

            do {
                let values = try fileURL.resourceValues(forKeys: [.totalFileAllocatedSizeKey, .isDirectoryKey])
                if let isDirectory = values.isDirectory, !isDirectory,
                   let fileSize = values.totalFileAllocatedSize {
                    totalSize += Int64(fileSize)
                }
            } catch {
                continue
            }
        }

        return totalSize
    }
}
