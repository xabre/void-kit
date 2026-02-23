import Foundation
import AppKit

struct ContainerInfo: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let path: String
    let bundleID: String
    let isOrphaned: Bool
    let appName: String?
    let appPath: String?
    let lastUsedDate: Date?

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: ContainerInfo, rhs: ContainerInfo) -> Bool {
        lhs.id == rhs.id
    }
}

class AppContainerScanner: ObservableObject {
    @Published var containers: [ContainerInfo] = []
    @Published var containerSizes: [UUID: Int64] = [:]
    @Published var calculatingContainers: Set<UUID> = []
    @Published var isScanning: Bool = false
    @Published var totalSize: Int64 = 0
    @Published var orphanedCount: Int = 0
    @Published var orphanedTotalSize: Int64 = 0

    private let fileManager = FileManager.default
    private var installedApps: [String: (name: String, path: String)] = [:]

    func scanContainers() {
        guard !isScanning else { return }
        isScanning = true
        containers = []
        containerSizes = [:]
        calculatingContainers = []
        totalSize = 0
        orphanedCount = 0
        orphanedTotalSize = 0

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }

            // First, scan for all installed applications
            self.scanInstalledApplications()

            let containersPath = self.fileManager.homeDirectoryForCurrentUser
                .appendingPathComponent("Library/Containers")

            guard self.fileManager.fileExists(atPath: containersPath.path) else {
                DispatchQueue.main.async {
                    self.isScanning = false
                }
                return
            }

            var containerInfos: [ContainerInfo] = []

            do {
                let contents = try self.fileManager.contentsOfDirectory(atPath: containersPath.path)

                for name in contents {
                    // Skip hidden files and non-directories
                    guard !name.hasPrefix(".") else { continue }

                    let fullPath = containersPath.appendingPathComponent(name).path
                    var isDir: ObjCBool = false

                    guard self.fileManager.fileExists(atPath: fullPath, isDirectory: &isDir),
                          isDir.boolValue else {
                        continue
                    }

                    // Extract bundle ID from container name
                    let bundleID = name

                    // Resolve the matching application
                    let resolved = self.resolveApplication(bundleID: bundleID)

                    // Get last-used date from container directory modification date
                    let containerURL = URL(fileURLWithPath: fullPath)
                    let lastUsedDate: Date? = try? containerURL.resourceValues(
                        forKeys: [.contentModificationDateKey]
                    ).contentModificationDate

                    let container = ContainerInfo(
                        name: name,
                        path: fullPath,
                        bundleID: bundleID,
                        isOrphaned: resolved == nil,
                        appName: resolved?.name,
                        appPath: resolved?.path,
                        lastUsedDate: lastUsedDate
                    )

                    containerInfos.append(container)
                }
            } catch {
                print("Error scanning containers: \(error)")
            }

            // Sort by name initially
            containerInfos.sort { $0.name < $1.name }

            // Update UI with initial results
            DispatchQueue.main.async {
                self.containers = containerInfos
                self.orphanedCount = containerInfos.filter { $0.isOrphaned }.count
            }

            // Calculate sizes in background
            let group = DispatchGroup()
            for container in containerInfos {
                group.enter()
                self.calculateSize(for: container) {
                    group.leave()
                }
            }

            group.notify(queue: .main) { [weak self] in
                guard let self = self else { return }
                self.totalSize = self.containerSizes.values.reduce(0, +)
                let orphanedIDs = Set(containerInfos.filter { $0.isOrphaned }.map { $0.id })
                self.orphanedTotalSize = self.containerSizes
                    .filter { orphanedIDs.contains($0.key) }
                    .values.reduce(0, +)
                self.isScanning = false
            }
        }
    }

    private func scanInstalledApplications() {
        installedApps.removeAll()

        // Use mdfind (Spotlight) to discover .app bundles system-wide.
        // Spotlight's index can be incomplete (missing apps that were installed
        // outside of the App Store, recently moved, or not yet indexed), so
        // always supplement with a directory walk of well-known locations.
        scanInstalledApplicationsViaMdfind()
        scanInstalledApplicationsViaDirectoryWalk()
    }

    /// Discover installed apps using Spotlight's mdfind command.
    private func scanInstalledApplicationsViaMdfind() {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/mdfind")
        process.arguments = ["kMDItemContentType == 'com.apple.application-bundle'"]

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = Pipe()

        do {
            try process.run()
            process.waitUntilExit()
        } catch {
            return
        }

        guard process.terminationStatus == 0 else { return }

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        guard let output = String(data: data, encoding: .utf8), !output.isEmpty else {
            return
        }

        let paths = output.components(separatedBy: "\n").filter { !$0.isEmpty }
        for path in paths {
            let url = URL(fileURLWithPath: path)
            if let bundle = Bundle(url: url),
               let bundleID = bundle.bundleIdentifier {
                let displayName = bundle.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String
                    ?? bundle.object(forInfoDictionaryKey: "CFBundleName") as? String
                    ?? url.deletingPathExtension().lastPathComponent
                installedApps[bundleID] = (name: displayName, path: path)
            }
        }
    }

    /// Fallback: scan hardcoded application directories.
    private func scanInstalledApplicationsViaDirectoryWalk() {
        let applicationURLs: [URL] = [
            URL(fileURLWithPath: "/Applications"),
            URL(fileURLWithPath: "/System/Applications"),
            fileManager.homeDirectoryForCurrentUser.appendingPathComponent("Applications")
        ]

        for applicationURL in applicationURLs {
            guard fileManager.fileExists(atPath: applicationURL.path) else {
                continue
            }

            guard let enumerator = fileManager.enumerator(
                at: applicationURL,
                includingPropertiesForKeys: [.isApplicationKey],
                options: [.skipsHiddenFiles]
            ) else {
                continue
            }

            for case let fileURL as URL in enumerator {
                if fileURL.pathExtension == "app" {
                    if let bundle = Bundle(url: fileURL),
                       let bundleID = bundle.bundleIdentifier {
                        let displayName = bundle.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String
                            ?? bundle.object(forInfoDictionaryKey: "CFBundleName") as? String
                            ?? fileURL.deletingPathExtension().lastPathComponent
                        installedApps[bundleID] = (name: displayName, path: fileURL.path)
                    }
                    enumerator.skipDescendants()
                }
            }
        }
    }

    private func resolveApplication(bundleID: String) -> (name: String, path: String)? {
        // 1. Check for exact match in our scanned apps
        if let app = installedApps[bundleID] {
            return app
        }

        // 2. Ask Launch Services — the authoritative source for installed apps.
        //    This catches apps that mdfind and directory walks may miss
        //    (e.g. App Store apps, apps in non-standard locations).
        if let result = resolveViaLaunchServices(bundleID: bundleID) {
            return result
        }

        // 3. Try stripping known distribution suffixes.
        //    Some apps use bundle IDs like "com.example.app.appstore" for the
        //    Mac App Store variant while the container may use either form.
        let knownSuffixes = [".appstore", ".macos", ".mac", ".mas"]
        for suffix in knownSuffixes {
            if bundleID.hasSuffix(suffix) {
                let stripped = String(bundleID.dropLast(suffix.count))
                if let app = installedApps[stripped] {
                    return app
                }
                if let result = resolveViaLaunchServices(bundleID: stripped) {
                    return result
                }
            }
        }

        // 4. Check if this container belongs to a helper/extension of an installed app.
        //    Helper apps typically have bundle IDs like "com.example.app.helper"
        //    where "com.example.app" is the main app's bundle ID.
        for (installedBundleID, app) in installedApps {
            if bundleID.hasPrefix(installedBundleID + ".") &&
               bundleID.count > installedBundleID.count + 1 {
                return app
            }
        }

        return nil
    }

    private func resolveViaLaunchServices(bundleID: String) -> (name: String, path: String)? {
        guard let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID) else {
            return nil
        }
        let bundle = Bundle(url: appURL)
        let displayName = bundle?.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String
            ?? bundle?.object(forInfoDictionaryKey: "CFBundleName") as? String
            ?? appURL.deletingPathExtension().lastPathComponent
        let result = (name: displayName, path: appURL.path)
        // Cache it so prefix matching can also find helpers
        installedApps[bundleID] = result
        return result
    }

    private func calculateSize(for container: ContainerInfo, completion: @escaping () -> Void) {
        DispatchQueue.global(qos: .utility).async { [weak self] in
            guard let self = self else {
                completion()
                return
            }

            DispatchQueue.main.async {
                self.calculatingContainers.insert(container.id)
            }

            let size = self.calculateDirectorySize(atPath: container.path)

            DispatchQueue.main.async {
                self.containerSizes[container.id] = size
                self.calculatingContainers.remove(container.id)
                completion()
            }
        }
    }

    private func calculateDirectorySize(atPath path: String) -> Int64 {
        var totalSize: Int64 = 0

        guard let enumerator = fileManager.enumerator(
            at: URL(fileURLWithPath: path),
            includingPropertiesForKeys: [.fileSizeKey, .isDirectoryKey],
            options: []
        ) else {
            return 0
        }

        for case let fileURL as URL in enumerator {
            do {
                let values = try fileURL.resourceValues(forKeys: [.fileSizeKey, .isDirectoryKey])
                if let isDirectory = values.isDirectory, !isDirectory,
                   let fileSize = values.fileSize {
                    totalSize += Int64(fileSize)
                }
            } catch {
                continue
            }
        }

        return totalSize
    }
}
