import Foundation
import AppKit

struct DeletionItem: Identifiable {
    let id: UUID
    let name: String
    let path: String
    let bundleID: String
    let size: Int64

    var formattedSize: String {
        ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
    }

    /// Whether this item came from the System Data tab (vs App Containers)
    var isSystemData: Bool {
        bundleID.isEmpty
    }
}

class DeletionManager: ObservableObject {
    @Published var selectedItems: [UUID: DeletionItem] = [:]
    @Published var isDeleting: Bool = false

    var itemCount: Int { selectedItems.count }

    var totalSelectedSize: Int64 {
        selectedItems.values.reduce(0) { $0 + $1.size }
    }

    var formattedTotalSize: String {
        ByteCountFormatter.string(fromByteCount: totalSelectedSize, countStyle: .file)
    }

    func isSelected(_ id: UUID) -> Bool {
        selectedItems[id] != nil
    }

    func toggle(container: ContainerInfo, size: Int64) {
        if selectedItems[container.id] != nil {
            selectedItems.removeValue(forKey: container.id)
        } else {
            let item = DeletionItem(
                id: container.id,
                name: container.appName ?? container.bundleID,
                path: container.path,
                bundleID: container.bundleID,
                size: size
            )
            selectedItems[container.id] = item
        }
    }

    func toggleFileSystemItem(_ fsItem: FileSystemItem) {
        if selectedItems[fsItem.id] != nil {
            selectedItems.removeValue(forKey: fsItem.id)
        } else {
            let item = DeletionItem(
                id: fsItem.id,
                name: fsItem.name,
                path: fsItem.path,
                bundleID: "",
                size: fsItem.size
            )
            selectedItems[fsItem.id] = item
        }
    }

    func remove(_ id: UUID) {
        selectedItems.removeValue(forKey: id)
    }

    func clearAll() {
        selectedItems.removeAll()
    }

    func deleteSelected() async -> Set<UUID> {
        await MainActor.run { isDeleting = true }

        var deletedIDs: Set<UUID> = []

        for (id, item) in selectedItems {
            let url = URL(fileURLWithPath: item.path)
            let success = await recycleFile(url)
            if success {
                deletedIDs.insert(id)
            }
        }

        await MainActor.run {
            for id in deletedIDs {
                selectedItems.removeValue(forKey: id)
            }
            isDeleting = false
        }

        return deletedIDs
    }

    private func recycleFile(_ url: URL) async -> Bool {
        await withCheckedContinuation { continuation in
            NSWorkspace.shared.recycle([url]) { trashedURLs, error in
                if let error = error {
                    print("Failed to trash \(url.path): \(error)")
                    continuation.resume(returning: false)
                } else {
                    continuation.resume(returning: !trashedURLs.isEmpty)
                }
            }
        }
    }
}
