import Foundation

class FileSystemItem: Identifiable, ObservableObject {
    let id = UUID()
    let name: String
    let path: String
    let isDirectory: Bool
    let requiresElevatedPermissions: Bool
    @Published var size: Int64 = 0
    @Published var children: [FileSystemItem] = []
    @Published var isExpanded: Bool = false
    @Published var isCalculating: Bool = false
    @Published var isAccessDenied: Bool = false

    init(name: String, path: String, isDirectory: Bool, requiresElevatedPermissions: Bool = false) {
        self.name = name
        self.path = path
        self.isDirectory = isDirectory
        self.requiresElevatedPermissions = requiresElevatedPermissions
    }

    var formattedSize: String {
        guard size > 0 else { return isAccessDenied ? "Access Denied" : "—" }
        return ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
    }
}

class FileSystemScanner: ObservableObject {
    @Published var rootItems: [FileSystemItem] = []
    @Published var isScanning: Bool = false
    @Published var totalSize: Int64 = 0

    private let fileManager = FileManager.default

    func scanSystemDataPaths() {
        guard !isScanning else { return }
        isScanning = true
        rootItems = []
        totalSize = 0

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }

            var items: [FileSystemItem] = []

            for location in SystemDataPaths.knownSystemDataLocations {
                let expandedPath = SystemDataPaths.expandPath(location.path)

                // Include the path in the tree whether or not we can read it,
                // so the user can see what's blocked.
                guard self.fileManager.fileExists(atPath: expandedPath) else { continue }

                let item = FileSystemItem(
                    name: (location.path as NSString).lastPathComponent,
                    path: expandedPath,
                    isDirectory: true,
                    requiresElevatedPermissions: location.requiresElevatedPermissions
                )

                // Detect permission issues immediately — a path may exist yet be unreadable.
                if !self.fileManager.isReadableFile(atPath: expandedPath) {
                    item.isAccessDenied = true
                }

                items.append(item)
            }

            // Show the tree immediately, then start calculating sizes.
            // isScanning stays true until every root-level size is done so the
            // button and indicator reflect the real completion state.
            DispatchQueue.main.async {
                self.rootItems = items.sorted { $0.name < $1.name }
            }

            let group = DispatchGroup()
            for item in items where !item.isAccessDenied {
                group.enter()
                self.calculateSize(for: item, completion: { [weak self] in
                    self?.totalSize = self?.rootItems.reduce(0) { $0 + $1.size } ?? 0
                    group.leave()
                })
            }

            group.notify(queue: .main) { [weak self] in
                self?.isScanning = false
            }
        }
    }

    func loadChildren(for item: FileSystemItem) {
        guard item.isDirectory, item.children.isEmpty, !item.isAccessDenied else { return }

        item.isCalculating = true

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }

            var children: [FileSystemItem] = []

            do {
                let contents = try self.fileManager.contentsOfDirectory(atPath: item.path)

                for name in contents {
                    let fullPath = (item.path as NSString).appendingPathComponent(name)
                    var isDir: ObjCBool = false

                    guard self.fileManager.fileExists(atPath: fullPath, isDirectory: &isDir) else {
                        continue
                    }

                    let childItem = FileSystemItem(
                        name: name,
                        path: fullPath,
                        isDirectory: isDir.boolValue
                    )

                    if !self.fileManager.isReadableFile(atPath: fullPath) {
                        childItem.isAccessDenied = true
                    } else {
                        self.calculateSize(for: childItem)
                    }

                    children.append(childItem)
                }
            } catch let error as NSError {
                // Propagate permission errors back to the item so the UI can reflect them.
                let isPermissionError = error.code == NSFileReadNoPermissionError
                    || error.domain == NSCocoaErrorDomain && error.code == 257
                DispatchQueue.main.async {
                    if isPermissionError { item.isAccessDenied = true }
                    item.isCalculating = false
                }
                return
            }

            DispatchQueue.main.async {
                item.children = children.sorted { a, b in
                    if a.isDirectory != b.isDirectory { return a.isDirectory }
                    return a.size > b.size
                }
                item.isCalculating = false
            }
        }
    }

    private func calculateSize(for item: FileSystemItem, completion: (() -> Void)? = nil) {
        DispatchQueue.global(qos: .utility).async {
            let size = self.calculateDirectorySize(atPath: item.path)
            DispatchQueue.main.async {
                item.size = size
                completion?()
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
