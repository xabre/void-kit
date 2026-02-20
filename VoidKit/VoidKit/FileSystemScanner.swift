import Foundation

class FileSystemItem: Identifiable, ObservableObject {
    let id = UUID()
    let name: String
    let path: String
    let isDirectory: Bool
    @Published var size: Int64 = 0
    @Published var children: [FileSystemItem] = []
    @Published var isExpanded: Bool = false
    @Published var isCalculating: Bool = false
    
    init(name: String, path: String, isDirectory: Bool) {
        self.name = name
        self.path = path
        self.isDirectory = isDirectory
    }
    
    var formattedSize: String {
        ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
    }
}

class FileSystemScanner: ObservableObject {
    @Published var rootItems: [FileSystemItem] = []
    @Published var isScanning: Bool = false
    
    private let fileManager = FileManager.default
    
    func scanSystemDataPaths() {
        isScanning = true
        rootItems = []
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            var items: [FileSystemItem] = []
            
            for pathString in SystemDataPaths.knownSystemDataLocations {
                let expandedPath = SystemDataPaths.expandPath(pathString)
                
                guard self.fileManager.fileExists(atPath: expandedPath) else {
                    continue
                }
                
                let item = FileSystemItem(
                    name: (pathString as NSString).lastPathComponent,
                    path: expandedPath,
                    isDirectory: true
                )
                
                items.append(item)
                
                // Calculate size in background
                self.calculateSize(for: item)
            }
            
            DispatchQueue.main.async {
                self.rootItems = items.sorted { $0.name < $1.name }
                self.isScanning = false
            }
        }
    }
    
    func loadChildren(for item: FileSystemItem) {
        guard item.isDirectory, item.children.isEmpty else { return }
        
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
                    
                    children.append(childItem)
                    
                    // Calculate size for child
                    self.calculateSize(for: childItem)
                }
            } catch {
                print("Error reading directory \(item.path): \(error)")
            }
            
            DispatchQueue.main.async {
                item.children = children.sorted { item1, item2 in
                    // Sort directories first, then by size descending
                    if item1.isDirectory != item2.isDirectory {
                        return item1.isDirectory
                    }
                    return item1.size > item2.size
                }
                item.isCalculating = false
            }
        }
    }
    
    private func calculateSize(for item: FileSystemItem) {
        DispatchQueue.global(qos: .utility).async {
            let size = self.calculateDirectorySize(atPath: item.path)
            
            DispatchQueue.main.async {
                item.size = size
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
                let resourceValues = try fileURL.resourceValues(forKeys: [.fileSizeKey, .isDirectoryKey])
                
                if let isDirectory = resourceValues.isDirectory, !isDirectory {
                    if let fileSize = resourceValues.fileSize {
                        totalSize += Int64(fileSize)
                    }
                }
            } catch {
                // Skip files we can't read
                continue
            }
        }
        
        return totalSize
    }
}
