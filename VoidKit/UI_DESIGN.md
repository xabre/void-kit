# VoidKit - UI Design

## Main Window Layout

```
┌─────────────────────────────────────────────────────────────────┐
│  VoidKit - System Data Explorer                    🔄 [Scan]    │
├─────────────────────────────────────────────────────────────────┤
│                                                                   │
│  ▼ 📁 Caches                                          2.3 GB    │
│    ▶ 📁 com.apple.Safari                             856 MB    │
│    ▶ 📁 com.apple.photos                             634 MB    │
│    ▶ 📁 com.microsoft.VSCode                         512 MB    │
│    ▼ 📁 org.chromium.Chromium                        234 MB    │
│      📄 Cache_Data                                   123 MB    │
│      📄 GPUCache                                      89 MB    │
│      📄 Code Cache                                    22 MB    │
│                                                                   │
│  ▼ 📁 Logs                                           456 MB     │
│    ▶ 📁 DiagnosticReports                            234 MB    │
│    ▶ 📁 CoreSimulator                                156 MB    │
│    📄 system.log                                      45 MB    │
│                                                                   │
│  ▼ 📁 Developer                                      45.6 GB    │
│    ▼ 📁 Xcode                                        45.2 GB    │
│      ▼ 📁 DerivedData                                34.5 GB    │
│        ▶ 📁 MyApp-abcdefgh                           12.3 GB    │
│        ▶ 📁 AnotherProject-xyz123                     8.9 GB    │
│      ▶ 📁 Archives                                    10.7 GB    │
│    ▶ 📁 CoreSimulator                                456 MB    │
│                                                                   │
│  ▶ 📁 Application Support                            8.9 GB     │
│  ▶ 📁 Safari                                         1.2 GB     │
│  ▶ 📁 Mail                                           890 MB     │
│  ▶ 📁 Messages                                       456 MB     │
│                                                                   │
└─────────────────────────────────────────────────────────────────┘

## Features Illustrated:

1. **Tree View Navigation**
   - Collapsible folders with disclosure triangles (▶/▼)
   - Hierarchical indentation for nested items
   - Icons distinguish folders (📁) from files (📄)

2. **Size Display**
   - Right-aligned size column
   - Human-readable format (GB, MB, KB)
   - Calculated recursively for directories

3. **Interactive Elements**
   - Click triangles to expand/collapse
   - Async loading of subfolder contents
   - Progress indicators during calculation

4. **Visual Hierarchy**
   - Items sorted by size (largest first)
   - Directories listed before files
   - Clear visual separation between levels

5. **Header Actions**
   - Scan button to refresh data
   - Progress indicator during scanning
   - Window title with app name
```

## Color Scheme

- **Folders**: Blue (#007AFF)
- **Files**: Gray/Secondary
- **Background**: System window color
- **Text**: System primary/secondary colors
- **Accent**: Default macOS accent color

## Interaction Flow

1. **App Launch**
   - Auto-scan starts immediately
   - Shows "Scanning..." indicator
   
2. **Browsing**
   - Click disclosure triangle to expand folder
   - Subfolder contents load on-demand
   - Size calculates in background
   
3. **Refresh**
   - Click "Scan" button
   - Clears existing data
   - Re-scans all locations

## Technical Implementation

- Built with SwiftUI
- Async/await for file operations
- ObservableObject for state management
- Lazy loading of tree nodes
- Background threads for size calculation
