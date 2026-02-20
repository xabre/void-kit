# Orphaned Containers Feature

## Overview

This feature adds the ability to detect and display orphaned application containers in `~/Library/Containers`. An orphaned container is a data directory left behind when an application is uninstalled.

## Problem Statement

When macOS applications are uninstalled, they often leave behind their container directories in `~/Library/Containers`. These directories can consume significant disk space and are not automatically cleaned up by the system. Users need a way to identify these orphaned containers to reclaim storage space.

## Solution

The Orphaned Containers feature scans the Containers directory and checks each container against installed applications. Containers whose applications are no longer installed are flagged as "orphaned" with clear visual indicators.

## UI Design

### Tab Navigation
```
┌────────────────────────────────────────────────────────────┐
│  [System Data]  [App Containers]                           │
└────────────────────────────────────────────────────────────┘
```

### App Containers Tab Layout
```
┌──────────────────────────────────────────────────────────────────┐
│  Application Containers        Total: 2.3 GB  Orphaned: 5       │
│  [ ] Orphaned Only  [Status▼|Name|Size]  🔄 Scan                │
├──────────────────────────────────────────────────────────────────┤
│                                                                   │
│  🟠 📦 com.example.deleted-app                      123 MB      │
│     Application not installed                                   │
│                                                                   │
│  🟢 📦 com.apple.Safari                             45 MB       │
│                                                                   │
│  🟠 📦 com.microsoft.removed-app                    89 MB       │
│     Application not installed                                   │
│                                                                   │
│  🟢 📦 com.google.Chrome                            234 MB      │
│                                                                   │
└──────────────────────────────────────────────────────────────────┘
```

### Visual Indicators

- **🟢 Green Circle**: Application is installed and active
- **🟠 Orange Circle**: Application is not installed (orphaned)
- **📦 Box Icon**: Container/package icon
- **Size**: Displayed in human-readable format (MB, GB)
- **Status Text**: "Application not installed" shown below orphaned containers

## Technical Implementation

### AppContainerScanner

**Key Methods:**
- `scanContainers()`: Scans ~/Library/Containers directory
- `isApplicationInstalled(bundleID:)`: Checks if app is installed using NSWorkspace
- `calculateSize(for:completion:)`: Calculates directory size asynchronously

**Data Structure:**
```swift
struct ContainerInfo: Identifiable {
    let id: UUID
    let name: String          // Bundle ID (e.g., com.example.app)
    let path: String          // Full path to container
    let bundleID: String      // Application bundle identifier
    let isOrphaned: Bool      // True if app is not installed
}
```

**Published Properties:**
- `containers: [ContainerInfo]` - List of all containers
- `containerSizes: [UUID: Int64]` - Size for each container
- `calculatingContainers: Set<UUID>` - Containers being calculated
- `isScanning: Bool` - Scanning state
- `totalSize: Int64` - Total size of all containers
- `orphanedCount: Int` - Number of orphaned containers

### Detection Logic

1. **Scan Phase**
   - Enumerate all directories in ~/Library/Containers
   - Skip hidden files (starting with .)
   - Extract bundle ID from directory name

2. **Verification Phase**
   - Use `NSWorkspace.shared.urlForApplication(withBundleIdentifier:)`
   - Check if returned URL exists on disk
   - Mark as orphaned if app not found or file doesn't exist

3. **Size Calculation Phase**
   - Calculate sizes asynchronously on background queue
   - Use FileManager's enumerator for recursive size calculation
   - Update UI on main queue

### User Interactions

1. **Scan Button**: Initiates scan of Containers directory
2. **Orphaned Only Checkbox**: Filters view to show only orphaned containers
3. **Sort Dropdown**: Sort by Status (orphaned first), Name, or Size
4. **Hover**: Shows full path in tooltip

## Benefits

1. **Disk Space Recovery**: Users can identify which containers can be safely removed
2. **Clear Visualization**: Color-coded status makes it easy to see orphaned containers
3. **Size Information**: Shows how much space each container is using
4. **Filtering**: Focus on orphaned containers when needed
5. **Safe Identification**: Doesn't delete anything, just identifies orphans

## Future Enhancements

Potential improvements for future versions:
- Delete functionality for orphaned containers
- Confirmation dialog before deletion
- Backup/restore capabilities
- Export list of orphaned containers
- Schedule periodic scans
- Notification when new orphans are detected

## Testing Recommendations

When testing this feature:
1. Verify container scanning works correctly
2. Test with known installed and uninstalled apps
3. Verify bundle ID matching is accurate
4. Check size calculations are correct
5. Test filtering and sorting functionality
6. Verify UI updates during scanning
7. Test with empty Containers directory
8. Test with permission issues

## Security Considerations

- Read-only access to ~/Library/Containers
- No automatic deletion of data
- User must explicitly take action to remove containers
- Full Disk Access permission may be required for some containers
- Bundle ID verification prevents false positives

## Performance

- Asynchronous scanning prevents UI freezing
- Background thread for size calculation
- Lazy loading approach for better responsiveness
- Progress indicators during scan
- Efficient use of NSWorkspace API

## Compatibility

- macOS 13.0 or later required
- Uses standard macOS APIs (NSWorkspace, FileManager)
- No external dependencies
- SwiftUI for modern UI
