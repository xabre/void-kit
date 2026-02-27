import Foundation

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
        tccProtectedPaths.contains(where: { path.hasPrefix($0) })
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
