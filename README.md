# VoidKit - macOS Storage Cleanup Tool

Free up space on your Mac by identifying and managing System Data.

## Overview

VoidKit is a macOS application designed to help you understand what's taking up space in the "System Data" category on your Mac. The app provides a tree view of all known System Data locations and displays the size of each folder and file, making it easy to identify large files and directories that may be candidates for cleanup.

## Features

- 🔍 **Comprehensive Scanning**: Automatically scans known System Data locations including:
  - User Library Caches
  - Application Support files
  - Logs and temporary files
  - Developer caches (Xcode DerivedData, Simulators)
  - Safari and browser data
  - Mail and Messages storage
  - System-level caches and logs

- 📊 **Tree View Display**: Hierarchical view of folders and files with expandable/collapsible navigation

- 📏 **Size Calculation**: Real-time calculation and display of folder and file sizes in human-readable format

- ⚡ **Performance**: Asynchronous scanning and size calculation to keep the UI responsive

## Requirements

- macOS 13.0 or later
- Xcode 15.0 or later (for building)

## Building the Project

1. Clone the repository:
   ```bash
   git clone https://github.com/xabre/void-kit.git
   cd void-kit
   ```

2. Open the Xcode project:
   ```bash
   open VoidKit/VoidKit.xcodeproj
   ```

3. Build and run the project in Xcode (⌘R)

## Usage

1. Launch VoidKit
2. Click the "Scan" button to start scanning System Data locations
3. Browse through the tree view to explore folders
4. Click the chevron icon next to folders to expand and see their contents
5. Size information is displayed on the right side for each item

## App Name Alternatives

During development, we considered several names:
- **VoidKit** (current) - Clean and minimal
- SpaceReclaim
- SystemSweep
- MacCleanse
- SpaceFinder
- DiskVoid
- ClearSpace
- StorageScout

## Project Structure

```
VoidKit/
├── VoidKit.xcodeproj/       # Xcode project file
└── VoidKit/                 # Source files
    ├── VoidKitApp.swift         # App entry point
    ├── ContentView.swift        # Main UI view with tree display
    ├── FileSystemScanner.swift  # File system scanning logic
    ├── SystemDataPaths.swift    # Known system data locations
    ├── Assets.xcassets/         # App icons and assets
    └── VoidKit.entitlements     # App permissions
```

## Technical Details

The app is built using:
- **SwiftUI** for the user interface
- **Foundation** for file system operations
- **Combine** for reactive updates

The app uses sandboxing and requests read-only file access permissions as needed.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is open source and available under the MIT License.

## Disclaimer

This tool is designed to help identify large files and folders. Always be careful when deleting system files and make sure you understand what you're removing before taking any action.
