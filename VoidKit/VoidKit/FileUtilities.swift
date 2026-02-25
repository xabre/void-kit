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
