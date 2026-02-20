# VoidKit Development Guide

## Project Overview

VoidKit is a macOS application that helps users identify and understand their System Data storage usage. The app scans known System Data locations and presents them in an interactive tree view with size information.

## Architecture

### Core Components

1. **VoidKitApp.swift**
   - Entry point of the application
   - Configures the main window
   - Uses SwiftUI's `@main` attribute

2. **ContentView.swift**
   - Main UI view
   - Manages the FileSystemScanner instance
   - Renders the tree view hierarchy
   - Handles user interactions (expand/collapse, scan)

3. **FileSystemScanner.swift**
   - Core logic for scanning file system
   - Manages async operations for size calculation
   - Maintains the tree of FileSystemItem objects
   - Handles directory enumeration

4. **SystemDataPaths.swift**
   - Defines known System Data locations
   - Provides path expansion utilities
   - Centralized location for adding new paths

5. **FileSystemItem.swift** (embedded in FileSystemScanner.swift)
   - Model representing a file or directory
   - Observable properties for reactive UI updates
   - Manages child items and expanded state

## Key Design Patterns

### Observable Objects
The app uses Combine's `ObservableObject` protocol for reactive updates:
- `FileSystemScanner`: Published properties trigger UI updates
- `FileSystemItem`: Each item is observable for individual updates

### Async Processing
File system operations run asynchronously:
- Background threads for scanning and size calculation
- Main thread for UI updates
- DispatchQueue for thread management

### Lazy Loading
Tree nodes load children on-demand:
- Children populate when user expands a folder
- Reduces initial load time
- Minimizes memory usage

## Adding New System Data Locations

To add new paths to scan, edit `SystemDataPaths.swift`:

```swift
static let knownSystemDataLocations: [String] = [
    // Existing paths...
    
    // Add your new path here:
    "~/Library/YourNewPath",
    "/System/Library/YourSystemPath"
]
```

Paths starting with `~` are automatically expanded to the user's home directory.

## Customizing the UI

### Changing Colors
Edit `ContentView.swift` to modify colors:
```swift
Image(systemName: item.isDirectory ? "folder.fill" : "doc.fill")
    .foregroundColor(item.isDirectory ? .blue : .secondary)  // Change here
```

### Adjusting Layout
Modify spacing and sizing in `ContentView.swift`:
```swift
private var indentation: CGFloat {
    CGFloat(level) * 20  // Change indentation per level
}
```

### Window Size
Change minimum window dimensions in `ContentView.swift`:
```swift
.frame(minWidth: 800, minHeight: 600)  // Adjust as needed
```

## Building and Testing

### Requirements
- macOS 13.0 or later
- Xcode 15.0 or later
- Swift 5.9 or later

### Build Steps
1. Open `VoidKit.xcodeproj` in Xcode
2. Select the VoidKit scheme
3. Choose your target (Mac or My Mac)
4. Press Cmd+R to build and run

### Debug Mode
Enable additional logging by modifying scanner methods:
```swift
private func calculateSize(for item: FileSystemItem) {
    print("Calculating size for: \(item.path)")  // Add logging
    // ... rest of method
}
```

## Performance Considerations

### Size Calculation
- Uses `FileManager.enumerator` for efficient traversal
- Runs on utility QoS for background processing
- Includes hidden files for comprehensive System Data scanning

### Memory Management
- Uses `[weak self]` in closures to prevent retain cycles
- Lazy loading prevents loading entire tree at once
- Only stores necessary file attributes

### Thread Safety
- File operations on background threads
- UI updates on main thread
- Published properties automatically dispatch to main thread

## Security and Permissions

### Entitlements
The app uses these entitlements (`VoidKit.entitlements`):
- `com.apple.security.app-sandbox`: Enables sandboxing
- `com.apple.security.files.user-selected.read-only`: Read access to user files
- `com.apple.security.files.user-selected.read-write`: Write access (future feature)

### File Access
- Currently read-only
- Some system paths may require elevated permissions
- Gracefully handles access denied errors

## Future Enhancement Ideas

### Features to Add
1. **File Deletion**: Add ability to delete files/folders
2. **Search**: Add search/filter functionality
3. **Export**: Export report to CSV or PDF
4. **Exclusions**: Allow users to exclude certain paths
5. **Scheduling**: Automatic periodic scans
6. **Notifications**: Alert when storage is low
7. **Visualizations**: Add charts and graphs
8. **Comparison**: Compare scans over time

### Code Improvements
1. **Unit Tests**: Add comprehensive test coverage
2. **Error Handling**: Improve error reporting to user
3. **Localization**: Add multi-language support
4. **Preferences**: Add user settings/preferences
5. **Caching**: Cache scan results for faster re-opening
6. **Progress**: More detailed progress reporting

## Common Issues

### Build Errors
- Ensure deployment target is macOS 13.0+
- Check Swift version compatibility
- Verify all files are included in target

### Runtime Issues
- Check Console.app for detailed error messages
- Verify file permissions for scanned locations
- Some system paths may be inaccessible without admin rights

### Performance Issues
- Reduce number of scanned locations
- Increase QoS priority for faster scanning
- Add pagination for large directories

## Contributing

When contributing to VoidKit:

1. **Follow Swift Style Guide**: Use Swift API Design Guidelines
2. **Add Comments**: Document complex logic
3. **Test Thoroughly**: Test on various macOS versions
4. **Update Documentation**: Keep this guide current
5. **Small PRs**: Keep changes focused and reviewable

## Resources

- [SwiftUI Documentation](https://developer.apple.com/documentation/swiftui)
- [FileManager Documentation](https://developer.apple.com/documentation/foundation/filemanager)
- [App Sandbox Guide](https://developer.apple.com/documentation/security/app_sandbox)
- [macOS Development](https://developer.apple.com/macos/)

## License

MIT License - See LICENSE file for details
