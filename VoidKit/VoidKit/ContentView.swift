import SwiftUI

struct ContentView: View {
    @StateObject private var scanner = FileSystemScanner()
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("VoidKit - System Data Explorer")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Spacer()
                
                if scanner.isScanning {
                    ProgressView()
                        .scaleEffect(0.7)
                }
                
                Button(action: {
                    scanner.scanSystemDataPaths()
                }) {
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
                    
                    Button(action: {
                        scanner.scanSystemDataPaths()
                    }) {
                        Label("Start Scan", systemImage: "play.fill")
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                    }
                    .buttonStyle(.borderedProminent)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        ForEach(scanner.rootItems) { item in
                            FileSystemItemView(item: item, scanner: scanner, level: 0)
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
        }
        .frame(minWidth: 800, minHeight: 600)
        .onAppear {
            scanner.scanSystemDataPaths()
        }
    }
}

struct FileSystemItemView: View {
    @ObservedObject var item: FileSystemItem
    @ObservedObject var scanner: FileSystemScanner
    let level: Int
    
    private var indentation: CGFloat {
        CGFloat(level) * 20
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 8) {
                // Indentation
                Color.clear
                    .frame(width: indentation)
                
                // Disclosure triangle for directories
                if item.isDirectory {
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            item.isExpanded.toggle()
                        }
                        
                        if item.isExpanded && item.children.isEmpty {
                            scanner.loadChildren(for: item)
                        }
                    }) {
                        Image(systemName: item.isExpanded ? "chevron.down" : "chevron.right")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(.secondary)
                            .frame(width: 12)
                    }
                    .buttonStyle(.plain)
                } else {
                    Color.clear
                        .frame(width: 12)
                }
                
                // Icon
                Image(systemName: item.isDirectory ? "folder.fill" : "doc.fill")
                    .foregroundColor(item.isDirectory ? .blue : .secondary)
                    .font(.system(size: 14))
                
                // Name
                Text(item.name)
                    .font(.system(size: 13))
                    .lineLimit(1)
                
                Spacer()
                
                // Size or loading indicator
                if item.isCalculating {
                    ProgressView()
                        .scaleEffect(0.6)
                } else {
                    Text(item.formattedSize)
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .contentShape(Rectangle())
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.clear)
            )
            
            // Children (if expanded)
            if item.isExpanded {
                ForEach(item.children) { child in
                    FileSystemItemView(item: child, scanner: scanner, level: level + 1)
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
