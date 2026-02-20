import Foundation
import AppKit

struct ContainerInfo: Identifiable {
    let id = UUID()
    let name: String
    let path: String
    let bundleID: String
    var size: Int64 = 0
    var isOrphaned: Bool = false
    var isCalculating: Bool = false
}

class AppContainerScanner: ObservableObject {
    @Published var containers: [ContainerInfo] = []
    @Published var isScanning: Bool = false
    @Published var totalSize: Int64 = 0
    @Published var orphanedCount: Int = 0
    
    private let fileManager = FileManager.default
    
    func scanContainers() {
        guard !isScanning else { return }
        isScanning = true
        containers = []
        totalSize = 0
        orphanedCount = 0
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
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
                    // Container names are typically the bundle ID itself
                    let bundleID = name
                    
                    // Check if the application is still installed
                    let isOrphaned = !self.isApplicationInstalled(bundleID: bundleID)
                    
                    var container = ContainerInfo(
                        name: name,
                        path: fullPath,
                        bundleID: bundleID,
                        isOrphaned: isOrphaned
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
            for index in containerInfos.indices {
                group.enter()
                self.calculateSize(for: index) {
                    group.leave()
                }
            }
            
            group.notify(queue: .main) { [weak self] in
                guard let self = self else { return }
                self.totalSize = self.containers.reduce(0) { $0 + $1.size }
                self.isScanning = false
            }
        }
    }
    
    private func isApplicationInstalled(bundleID: String) -> Bool {
        // Use NSWorkspace to find applications by bundle identifier
        let workspace = NSWorkspace.shared
        
        // Try to get the URL for the application with this bundle ID
        if let appURL = workspace.urlForApplication(withBundleIdentifier: bundleID) {
            // Check if the application file actually exists at that location
            return fileManager.fileExists(atPath: appURL.path)
        }
        
        return false
    }
    
    private func calculateSize(for index: Int, completion: @escaping () -> Void) {
        DispatchQueue.global(qos: .utility).async { [weak self] in
            guard let self = self,
                  index < self.containers.count else {
                completion()
                return
            }
            
            DispatchQueue.main.async {
                if index < self.containers.count {
                    self.containers[index].isCalculating = true
                }
            }
            
            let path = self.containers[index].path
            let size = self.calculateDirectorySize(atPath: path)
            
            DispatchQueue.main.async {
                if index < self.containers.count {
                    self.containers[index].size = size
                    self.containers[index].isCalculating = false
                }
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
