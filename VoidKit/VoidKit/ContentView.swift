import SwiftUI

enum SortOrder {
    case name, size
}

struct ContentView: View {
    @StateObject private var scanner = FileSystemScanner()
    @StateObject private var permissions = PermissionsManager()
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
                Text("VoidKit - System Data Explorer")
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

            // Permission banner — shown until Full Disk Access is granted
            if !permissions.hasFullDiskAccess {
                PermissionBannerView(permissions: permissions)
                Divider()
            }

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
                ZStack {
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 0) {
                            ForEach(sortedItems) { item in
                                FileSystemItemView(item: item, scanner: scanner, level: 0, sortOrder: sortOrder)
                            }
                        }
                        .padding(.vertical, 8)
                    }

                    if scanner.isScanning {
                        VStack(spacing: 12) {
                            ProgressView()
                                .scaleEffect(1.2)
                            Text("Scanning…")
                                .font(.system(size: 13))
                                .foregroundColor(.secondary)
                        }
                        .padding(24)
                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
                        .shadow(radius: 8)
                    }
                }
            }
        }
        .frame(minWidth: 800, minHeight: 600)
        .onAppear {
            scanner.scanSystemDataPaths()
        }
        // Re-check permissions when the user returns from System Settings
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            permissions.checkPermissions()
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
    let level: Int
    let sortOrder: SortOrder

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

                // Name
                Text(item.name)
                    .font(.system(size: 13))
                    .foregroundColor(item.isAccessDenied ? .secondary : .primary)
                    .lineLimit(1)

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
            .help(item.path)

            if item.isExpanded && !item.isAccessDenied {
                ForEach(sortedChildren) { child in
                    FileSystemItemView(item: child, scanner: scanner, level: level + 1, sortOrder: sortOrder)
                }
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
