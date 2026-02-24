import SwiftUI

enum ContainerSortOrder {
    case name, size, status, lastUsed
}

struct OrphanedContainersView: View {
    @StateObject private var scanner = AppContainerScanner()
    @EnvironmentObject var deletionManager: DeletionManager
    @State private var sortOrder: ContainerSortOrder = .status
    @State private var showOnlyOrphaned: Bool = false
    @State private var hideAppleApps: Bool = true

    private var filteredAndSortedContainers: [ContainerInfo] {
        var containers = scanner.containers

        // Filter
        if hideAppleApps {
            containers = containers.filter { !$0.bundleID.hasPrefix("com.apple.") }
        }
        if showOnlyOrphaned {
            containers = containers.filter { $0.isOrphaned }
        }

        // Sort
        switch sortOrder {
        case .name:
            return containers.sorted { $0.name < $1.name }
        case .size:
            return containers.sorted {
                let sizeA = scanner.containerSizes[$0.id] ?? 0
                let sizeB = scanner.containerSizes[$1.id] ?? 0
                return sizeA > sizeB
            }
        case .status:
            return containers.sorted { a, b in
                if a.isOrphaned != b.isOrphaned {
                    return a.isOrphaned  // Orphaned items first
                }
                let sizeA = scanner.containerSizes[a.id] ?? 0
                let sizeB = scanner.containerSizes[b.id] ?? 0
                return sizeA > sizeB  // Then by size
            }
        case .lastUsed:
            return containers.sorted { a, b in
                let dateA = a.lastUsedDate ?? .distantPast
                let dateB = b.lastUsedDate ?? .distantPast
                return dateA > dateB  // Most recently used first
            }
        }
    }

    private var orphanedContainers: [ContainerInfo] {
        filteredAndSortedContainers.filter { $0.isOrphaned }
    }

    private var allOrphanedSelected: Bool {
        let orphaned = orphanedContainers
        guard !orphaned.isEmpty else { return false }
        return orphaned.allSatisfy { deletionManager.isSelected($0.id) }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 6) {
                HStack {
                    Text("Application Containers")
                        .font(.title2)
                        .fontWeight(.semibold)

                    Spacer()

                    if !scanner.containers.isEmpty {
                        VStack(alignment: .trailing, spacing: 1) {
                            Text("Total")
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                            Text(ByteCountFormatter.string(fromByteCount: scanner.totalSize, countStyle: .file))
                                .font(.system(size: 13, weight: .medium, design: .monospaced))
                        }

                        if scanner.orphanedCount > 0 {
                            VStack(alignment: .trailing, spacing: 1) {
                                Text("Orphaned")
                                    .font(.system(size: 10))
                                    .foregroundColor(.orange)
                                HStack(spacing: 4) {
                                    Text("\(scanner.orphanedCount)")
                                        .font(.system(size: 13, weight: .medium, design: .monospaced))
                                    if scanner.orphanedTotalSize > 0 {
                                        Text("(\(ByteCountFormatter.string(fromByteCount: scanner.orphanedTotalSize, countStyle: .file)))")
                                            .font(.system(size: 11, design: .monospaced))
                                    }
                                }
                                .foregroundColor(.orange)
                            }
                            .padding(.leading, 12)
                        }
                    }

                    if scanner.isScanning {
                        ProgressView()
                            .scaleEffect(0.7)
                    }

                    Button(action: { scanner.scanContainers() }) {
                        Label("Scan", systemImage: "arrow.clockwise")
                    }
                    .disabled(scanner.isScanning)
                }

                HStack(spacing: 12) {
                    Text("Find orphaned containers left behind by uninstalled apps. Select orphaned items to queue for deletion.")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                        .lineLimit(1)

                    Spacer()

                    if !orphanedContainers.isEmpty {
                        Button(action: {
                            if allOrphanedSelected {
                                for container in orphanedContainers {
                                    deletionManager.remove(container.id)
                                }
                            } else {
                                for container in orphanedContainers {
                                    if !deletionManager.isSelected(container.id) {
                                        let size = scanner.containerSizes[container.id] ?? 0
                                        deletionManager.toggle(container: container, size: size)
                                    }
                                }
                            }
                        }) {
                            Label(allOrphanedSelected ? "Deselect All" : "Select All Orphaned",
                                  systemImage: allOrphanedSelected ? "xmark.circle" : "checkmark.circle")
                        }
                        .buttonStyle(.bordered)
                    }

                    Toggle("Hide Apple", isOn: $hideAppleApps)
                        .toggleStyle(.checkbox)
                        .disabled(scanner.containers.isEmpty)

                    Toggle("Orphaned Only", isOn: $showOnlyOrphaned)
                        .toggleStyle(.checkbox)
                        .disabled(scanner.containers.isEmpty)

                    Picker("Sort by", selection: $sortOrder) {
                        Text("Status").tag(ContainerSortOrder.status)
                        Text("Name").tag(ContainerSortOrder.name)
                        Text("Size").tag(ContainerSortOrder.size)
                        Text("Last Used").tag(ContainerSortOrder.lastUsed)
                    }
                    .labelsHidden()
                    .pickerStyle(.segmented)
                    .frame(width: 240)
                    .disabled(scanner.containers.isEmpty)
                }
            }
            .padding()
            .background(Color(NSColor.windowBackgroundColor))

            Divider()

            // Content area
            if scanner.containers.isEmpty && !scanner.isScanning {
                VStack(spacing: 20) {
                    Image(systemName: "shippingbox")
                        .font(.system(size: 60))
                        .foregroundColor(.secondary)

                    Text("No containers scanned yet")
                        .font(.title3)
                        .foregroundColor(.secondary)

                    Text("Click 'Scan' to check application containers in ~/Library/Containers")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)

                    Button(action: { scanner.scanContainers() }) {
                        Label("Start Scan", systemImage: "play.fill")
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(scanner.isScanning)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        ForEach(Array(filteredAndSortedContainers.enumerated()), id: \.element.id) { index, container in
                            ContainerItemView(
                                container: container,
                                size: scanner.containerSizes[container.id] ?? 0,
                                isCalculating: scanner.calculatingContainers.contains(container.id),
                                isSelected: deletionManager.isSelected(container.id),
                                index: index,
                                onToggleSelection: container.isOrphaned ? {
                                    deletionManager.toggle(
                                        container: container,
                                        size: scanner.containerSizes[container.id] ?? 0
                                    )
                                } : nil
                            )
                        }
                    }
                    .padding(.vertical, 8)
                }
            }

            // Status bar
            if deletionManager.itemCount > 0 {
                Divider()
                HStack(spacing: 8) {
                    Image(systemName: "trash")
                        .font(.system(size: 11))
                        .foregroundColor(.red)
                    Text("\(deletionManager.itemCount) item\(deletionManager.itemCount == 1 ? "" : "s") queued for deletion")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                    Text(deletionManager.formattedTotalSize)
                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                        .foregroundColor(.red)
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color(NSColor.windowBackgroundColor))
            }
        }
        .onAppear {
            scanner.scanContainers()
        }
    }
}

// MARK: - Container Item View

struct ContainerItemView: View {
    let container: ContainerInfo
    let size: Int64
    let isCalculating: Bool
    var isSelected: Bool = false
    var index: Int = 0
    var onToggleSelection: (() -> Void)? = nil
    @State private var isHovered = false

    private static let relativeDateFormatter: RelativeDateTimeFormatter = {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter
    }()

    var body: some View {
        HStack(spacing: 8) {
            // Checkbox for orphaned containers
            if let toggleAction = onToggleSelection {
                Button(action: toggleAction) {
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 16))
                        .foregroundColor(isSelected ? .red : .secondary)
                }
                .buttonStyle(.plain)
                .padding(.leading, 12)
            } else {
                Color.clear.frame(width: 4)
            }

            // Status indicator
            Circle()
                .fill(container.isOrphaned ? Color.orange : Color.green)
                .frame(width: 8, height: 8)
                .padding(.leading, onToggleSelection == nil ? 12 : 0)

            // Icon
            Image(systemName: container.isOrphaned ? "shippingbox.fill" : "shippingbox")
                .foregroundColor(container.isOrphaned ? .orange : .blue)
                .font(.system(size: 14))
                .frame(width: 22, height: 18)

            // Name and details
            VStack(alignment: .leading, spacing: 2) {
                Text(container.appName ?? container.bundleID)
                    .font(.system(size: 13))
                    .foregroundColor(.primary)
                    .lineLimit(1)

                Text(container.bundleID)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                    .lineLimit(1)

                if let appPath = container.appPath {
                    Text(appPath)
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                } else {
                    Text("App not installed")
                        .font(.system(size: 11))
                        .foregroundColor(.orange)
                }
            }

            Spacer()

            // Size and last-used date
            VStack(alignment: .trailing, spacing: 2) {
                if isCalculating {
                    ProgressView().scaleEffect(0.6)
                } else if size > 0 {
                    Text(ByteCountFormatter.string(fromByteCount: size, countStyle: .file))
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundColor(.secondary)
                } else {
                    Text("—")
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundColor(.secondary)
                }

                if let date = container.lastUsedDate {
                    Text(Self.relativeDateFormatter.localizedString(for: date, relativeTo: Date()))
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(rowBackground(index: index, isHovered: isHovered))
        .onHover { hovering in
            isHovered = hovering
        }
        .contentShape(Rectangle())
        .help(container.path)
        .contextMenu {
            Button {
                NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: container.path)
            } label: {
                Label("Open in Finder", systemImage: "folder")
            }

            if let appPath = container.appPath {
                Button {
                    NSWorkspace.shared.activateFileViewerSelecting([URL(fileURLWithPath: appPath)])
                } label: {
                    Label("Show App in Finder", systemImage: "app")
                }
            }

            Button {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(container.path, forType: .string)
            } label: {
                Label("Copy Path", systemImage: "doc.on.doc")
            }

            Button {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(container.bundleID, forType: .string)
            } label: {
                Label("Copy Bundle ID", systemImage: "number")
            }
        }
    }
}

#Preview {
    OrphanedContainersView()
        .environmentObject(DeletionManager())
}
