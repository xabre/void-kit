import SwiftUI

enum SortOrder {
    case name, size
}

struct ContentView: View {
    @StateObject private var permissions = PermissionsManager()
    @EnvironmentObject var deletionManager: DeletionManager
    @State private var selectedTab: Tab = .systemData

    enum Tab {
        case systemData
        case orphanedContainers
        case reviewDelete
    }

    var body: some View {
        VStack(spacing: 0) {
            // Tab bar
            HStack(spacing: 0) {
                TabButton(
                    title: "System Data",
                    icon: "folder.fill",
                    isSelected: selectedTab == .systemData
                ) {
                    selectedTab = .systemData
                }

                TabButton(
                    title: "App Containers",
                    icon: "shippingbox.fill",
                    isSelected: selectedTab == .orphanedContainers
                ) {
                    selectedTab = .orphanedContainers
                }

                TabButton(
                    title: "Review & Delete",
                    icon: "trash.fill",
                    isSelected: selectedTab == .reviewDelete,
                    badgeText: deletionManager.itemCount > 0 ? deletionManager.formattedTotalSize : nil,
                    badgeColor: .red
                ) {
                    selectedTab = .reviewDelete
                }

                Spacer()
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(Color(NSColor.windowBackgroundColor))

            Divider()

            // Permission banner — shown until Full Disk Access is granted
            if !permissions.hasFullDiskAccess {
                PermissionBannerView(permissions: permissions)
                Divider()
            }

            // Tab content
            switch selectedTab {
            case .systemData:
                SystemDataView()
            case .orphanedContainers:
                OrphanedContainersView()
            case .reviewDelete:
                ReviewDeleteView()
            }
        }
        .frame(minWidth: 800, minHeight: 600)
        .preferredColorScheme(.dark)
        // Re-check permissions when the user returns from System Settings
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            permissions.checkPermissions()
        }
    }
}

// MARK: - Tab Button

struct TabButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    var badgeText: String? = nil
    var badgeColor: Color = .red
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                Text(title)
                    .font(.system(size: 13, weight: .medium))

                if let badge = badgeText {
                    Text(badge)
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(badgeColor))
                }
            }
            .foregroundColor(isSelected ? .primary : .secondary)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                isSelected ? Color.accentColor.opacity(0.12) : Color.clear,
                in: RoundedRectangle(cornerRadius: 6)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(isSelected ? Color.accentColor.opacity(0.3) : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - System Data View

struct SystemDataView: View {
    @StateObject private var scanner = FileSystemScanner()
    @State private var sortOrder: SortOrder = .name

    private var sortedItems: [FileSystemItem] {
        switch sortOrder {
        case .name: return scanner.rootItems.sorted { $0.name < $1.name }
        case .size: return scanner.rootItems.sorted { $0.size > $1.size }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("System Data Explorer")
                    .font(.title2)
                    .fontWeight(.semibold)

                Spacer()

                if !scanner.rootItems.isEmpty {
                    VStack(alignment: .trailing, spacing: 1) {
                        Text("Total")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                        Text(ByteCountFormatter.string(fromByteCount: scanner.totalSize, countStyle: .file))
                            .font(.system(size: 13, weight: .medium, design: .monospaced))
                    }
                }

                if scanner.isScanning {
                    ProgressView()
                        .scaleEffect(0.7)
                }

                Picker("Sort by", selection: $sortOrder) {
                    Text("Name").tag(SortOrder.name)
                    Text("Size").tag(SortOrder.size)
                }
                .labelsHidden()
                .pickerStyle(.segmented)
                .frame(width: 120)
                .disabled(scanner.rootItems.isEmpty)

                Button(action: { scanner.scanSystemDataPaths() }) {
                    Label("Scan", systemImage: "arrow.clockwise")
                }
                .disabled(scanner.isScanning)
            }
            .padding()
            .background(Color(NSColor.windowBackgroundColor))

            Divider()

            // Content area
            if scanner.rootItems.isEmpty && !scanner.isScanning {
                VStack(spacing: 20) {
                    Image(systemName: "folder.badge.questionmark")
                        .font(.system(size: 60))
                        .foregroundColor(.secondary)

                    Text("No data scanned yet")
                        .font(.title3)
                        .foregroundColor(.secondary)

                    Text("Click 'Scan' to analyze system data locations")
                        .font(.body)
                        .foregroundColor(.secondary)

                    Button(action: { scanner.scanSystemDataPaths() }) {
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
                        ForEach(Array(sortedItems.enumerated()), id: \.element.id) { index, item in
                            FileSystemItemView(item: item, scanner: scanner, level: 0, sortOrder: sortOrder, index: index)
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
        }
        .onAppear {
            scanner.scanSystemDataPaths()
        }
    }
}

// MARK: - Permission Banner

struct PermissionBannerView: View {
    @ObservedObject var permissions: PermissionsManager

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "lock.shield.fill")
                .font(.system(size: 22))
                .foregroundColor(.orange)

            VStack(alignment: .leading, spacing: 2) {
                Text("Full Disk Access Required")
                    .font(.system(size: 13, weight: .semibold))
                Text("Some system folders are hidden without it. Grant access in System Settings, then click Re-check.")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }

            Spacer()

            Button("Re-check") {
                permissions.checkPermissions()
            }

            Button("Open Settings") {
                permissions.openFullDiskAccessSettings()
            }
            .buttonStyle(.borderedProminent)
            .tint(.orange)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color.orange.opacity(0.08))
    }
}

// MARK: - File System Item View

struct FileSystemItemView: View {
    @ObservedObject var item: FileSystemItem
    @ObservedObject var scanner: FileSystemScanner
    @EnvironmentObject var deletionManager: DeletionManager
    let level: Int
    let sortOrder: SortOrder
    var index: Int = 0
    @State private var isHovered = false

    private var isRootItem: Bool { level == 0 }
    private var indentation: CGFloat { CGFloat(level) * 20 }

    private var sortedChildren: [FileSystemItem] {
        switch sortOrder {
        case .name:
            return item.children.sorted { a, b in
                if a.isDirectory != b.isDirectory { return a.isDirectory }
                return a.name < b.name
            }
        case .size:
            return item.children.sorted { a, b in
                if a.isDirectory != b.isDirectory { return a.isDirectory }
                return a.size > b.size
            }
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 8) {
                Color.clear.frame(width: indentation)

                // Checkbox
                if !item.isAccessDenied {
                    Button(action: { deletionManager.toggleFileSystemItem(item) }) {
                        Image(systemName: deletionManager.isSelected(item.id) ? "checkmark.circle.fill" : "circle")
                            .font(.system(size: 14))
                            .foregroundColor(deletionManager.isSelected(item.id) ? .red : .secondary)
                    }
                    .buttonStyle(.plain)
                }

                // Safety dot for root items
                if isRootItem, let safety = item.safetyLevel {
                    Circle()
                        .fill(safetyColor(safety))
                        .frame(width: 8, height: 8)
                }

                // Disclosure / lock indicator
                if item.isAccessDenied {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.orange)
                        .frame(width: 12)
                } else if item.isDirectory {
                    Image(systemName: item.isExpanded ? "chevron.down" : "chevron.right")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.secondary)
                        .frame(width: 12)
                } else {
                    Color.clear.frame(width: 12)
                }

                // Icon
                ZStack(alignment: .bottomTrailing) {
                    Image(systemName: item.isDirectory ? "folder.fill" : "doc.fill")
                        .foregroundColor(item.isAccessDenied ? .orange.opacity(0.7) : (item.isDirectory ? .blue : .secondary))
                        .font(.system(size: 14))

                    if item.requiresElevatedPermissions && item.isDirectory {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 7, weight: .bold))
                            .foregroundColor(.white)
                            .padding(1.5)
                            .background(item.isAccessDenied ? Color.orange : Color.secondary,
                                        in: Circle())
                            .offset(x: 5, y: 3)
                    }
                }
                .frame(width: 22, height: 18)

                // Name + safety label + description
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(item.name)
                            .font(.system(size: 13))
                            .foregroundColor(item.isAccessDenied ? .secondary : .primary)
                            .lineLimit(1)

                        if isRootItem, let safety = item.safetyLevel {
                            Text(safety.label)
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(safetyColor(safety))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(
                                    Capsule()
                                        .fill(safetyColor(safety).opacity(0.12))
                                )
                        }
                    }

                    if isRootItem, let displayPath = item.displayPath {
                        Text(displayPath)
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }

                    if isRootItem, let desc = item.safetyDescription {
                        Text(desc)
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }

                Spacer()

                // Size / status
                if item.isCalculating {
                    ProgressView().scaleEffect(0.6)
                } else {
                    Text(item.formattedSize)
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundColor(item.isAccessDenied ? .orange : .secondary)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(rowBackground(index: index, isHovered: isHovered))
            .onHover { hovering in
                isHovered = hovering
            }
            .contentShape(Rectangle())
            .onTapGesture {
                guard item.isDirectory, !item.isAccessDenied else { return }
                withAnimation(.easeInOut(duration: 0.2)) {
                    item.isExpanded.toggle()
                }
                if item.isExpanded && item.children.isEmpty {
                    scanner.loadChildren(for: item)
                }
            }
            .help(isRootItem && item.safetyDescription != nil ? item.safetyDescription! : item.path)
            .contextMenu {
                Button {
                    if item.isDirectory {
                        NSWorkspace.shared.open(URL(fileURLWithPath: item.path))
                    } else {
                        NSWorkspace.shared.activateFileViewerSelecting([URL(fileURLWithPath: item.path)])
                    }
                } label: {
                    Label(item.isDirectory ? "Open in Finder" : "Show in Finder", systemImage: "folder")
                }

                Button {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(item.path, forType: .string)
                } label: {
                    Label("Copy Path", systemImage: "doc.on.doc")
                }
            }

            if item.isExpanded && !item.isAccessDenied {
                ForEach(Array(sortedChildren.enumerated()), id: \.element.id) { childIndex, child in
                    FileSystemItemView(item: child, scanner: scanner, level: level + 1, sortOrder: sortOrder, index: childIndex)
                }
            }
        }
    }

    private func safetyColor(_ level: SafetyLevel) -> Color {
        switch level {
        case .safe: return .green
        case .caution: return .yellow
        case .unsafe: return .red
        }
    }
}

// MARK: - Row Background Helper

func rowBackground(index: Int, isHovered: Bool) -> Color {
    if isHovered {
        return Color.white.opacity(0.06)
    } else if index % 2 == 1 {
        return Color(NSColor.separatorColor).opacity(0.08)
    } else {
        return Color.clear
    }
}

#Preview {
    ContentView()
        .environmentObject(DeletionManager())
}
