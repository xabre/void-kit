# UI Mockup - Orphaned Containers Feature

## Main Window with Tabs

```
┌─────────────────────────────────────────────────────────────────────────┐
│                                                                          │
│  ╔═══════════════╗  ╔═══════════════╗                                  │
│  ║ System Data   ║  ║ App Containers║                                  │
│  ╚═══════════════╝  ╚═══════════════╝                                  │
│  └─ Active Tab       └─ New Feature                                    │
│                                                                          │
├──────────────────────────────────────────────────────────────────────────┤
│  Application Containers            Total: 2.3 GB   Orphaned: 5         │
│                                    ☑ Orphaned Only                      │
│  [Status ▼] [Name] [Size]         🔄 Scan                              │
├──────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│  🟠 📦 com.adobe.removed-app                                123.5 MB   │
│     ↳ Application not installed                                         │
│                                                                          │
│  🟠 📦 com.example.deleted-tool                             89.2 MB    │
│     ↳ Application not installed                                         │
│                                                                          │
│  🟢 📦 com.apple.Safari                                     45.8 MB    │
│                                                                          │
│  🟠 📦 com.microsoft.old-office-tool                        234.1 MB   │
│     ↳ Application not installed                                         │
│                                                                          │
│  🟢 📦 com.google.Chrome                                    178.4 MB   │
│                                                                          │
│  🟠 📦 com.jetbrains.uninstalled-ide                        456.9 MB   │
│     ↳ Application not installed                                         │
│                                                                          │
│  🟢 📦 com.apple.mail                                       67.3 MB    │
│                                                                          │
│  🟠 📦 com.trial.expired-app                                12.8 MB    │
│     ↳ Application not installed                                         │
│                                                                          │
└──────────────────────────────────────────────────────────────────────────┘
```

## Tab Navigation Detail

### System Data Tab (Existing)
```
┌──────────────────────────────────────────────────────────────┐
│  [● System Data]  [ App Containers]                          │
│                                                               │
│  System Data Explorer                                        │
│  └─ Shows tree view of system data locations                 │
│  └─ Expandable folders                                       │
│  └─ Size calculations                                        │
└──────────────────────────────────────────────────────────────┘
```

### App Containers Tab (New)
```
┌──────────────────────────────────────────────────────────────┐
│  [ System Data]  [● App Containers]                          │
│                                                               │
│  Application Containers                                      │
│  └─ Shows list of all containers                             │
│  └─ Color-coded status (green/orange)                        │
│  └─ Filter by orphaned status                                │
│  └─ Sort by name, size, or status                            │
└──────────────────────────────────────────────────────────────┘
```

## Visual Elements

### Status Indicators
- 🟢 **Green Dot** + Regular Icon → Application is installed
- 🟠 **Orange Dot** + Bold Icon → Application NOT installed (orphaned)

### Container List Item
```
┌──────────────────────────────────────────────────────┐
│ 🟠 📦 com.example.app                     123 MB    │
│    ↳ Application not installed                      │
└──────────────────────────────────────────────────────┘
     │  │  └─ Bundle ID                   └─ Size
     │  └─ Container Icon
     └─ Status Color (orange = orphaned)
```

### Header Controls
```
┌──────────────────────────────────────────────────────────┐
│ Application Containers    Total: 2.3 GB  Orphaned: 5    │
│                          ☑ Orphaned Only                 │
│ [Sort Dropdown ▼]        🔄 Scan                        │
└──────────────────────────────────────────────────────────┘
```

## User Workflow

### 1. Initial State
```
┌─────────────────────────────────────┐
│  [ System Data]  [App Containers]   │
├─────────────────────────────────────┤
│                                     │
│         📦                          │
│                                     │
│  No containers scanned yet          │
│                                     │
│  [Start Scan ▶]                    │
│                                     │
└─────────────────────────────────────┘
```

### 2. Scanning State
```
┌─────────────────────────────────────┐
│  [ System Data]  [App Containers]   │
├─────────────────────────────────────┤
│                                     │
│         ⏳                          │
│                                     │
│  Scanning containers...             │
│                                     │
│        [Progress Indicator]         │
│                                     │
└─────────────────────────────────────┘
```

### 3. Results with All Containers
```
┌─────────────────────────────────────────────────┐
│  Total: 2.3 GB  Orphaned: 5                     │
│  ☐ Orphaned Only    [Status ▼]    🔄 Scan      │
├─────────────────────────────────────────────────┤
│  🟠 com.deleted.app              123 MB        │
│  🟢 com.apple.Safari              45 MB        │
│  🟠 com.removed.tool              89 MB        │
│  🟢 com.google.Chrome            178 MB        │
│  🟠 com.old.app                  234 MB        │
└─────────────────────────────────────────────────┘
```

### 4. Results with Orphaned Only Filter
```
┌─────────────────────────────────────────────────┐
│  Total: 2.3 GB  Orphaned: 5                     │
│  ☑ Orphaned Only    [Status ▼]    🔄 Scan      │
├─────────────────────────────────────────────────┤
│  🟠 com.deleted.app              123 MB        │
│  🟠 com.removed.tool              89 MB        │
│  🟠 com.old.app                  234 MB        │
│  🟠 com.trial.app                 13 MB        │
│  🟠 com.uninstalled.app          457 MB        │
└─────────────────────────────────────────────────┘
```

## Color Scheme

### Status Colors
- **Green (#34C759)**: Application is installed
- **Orange (#FF9500)**: Application is orphaned
- **Blue (#007AFF)**: Accent color for interactive elements
- **Gray (#8E8E93)**: Secondary text and inactive elements

### Typography
- **System Font**: San Francisco (macOS default)
- **Sizes**: 
  - Tab title: 13pt medium
  - Header: 16pt semibold
  - Bundle ID: 13pt regular
  - Status text: 11pt regular
  - Size: 12pt monospaced

## Interactive Elements

### Clickable Areas
1. **Tab Buttons**: Switch between System Data and App Containers
2. **Scan Button**: Refresh container list
3. **Orphaned Only Checkbox**: Toggle filter
4. **Sort Dropdown**: Change sort order
5. **Container Rows**: Show path in tooltip on hover

### Hover States
```
Normal:  🟠 📦 com.example.app          123 MB
Hover:   🟠 📦 com.example.app          123 MB  ← highlighted
         Tooltip: /Users/name/Library/Containers/com.example.app
```

## Accessibility

- Color-blind friendly: Icons + colors + text labels
- VoiceOver support: All elements properly labeled
- Keyboard navigation: Tab through all controls
- Tooltips: Show full paths on hover
- Clear status indicators: Both visual and textual

## Responsive Behavior

### During Scan
- Progress indicator in overlay
- Scan button disabled
- Results appear as they're found
- Size calculations happen in background

### Empty States
- Clear message when no containers found
- Prominent "Start Scan" button
- Icon to indicate what to expect

### Error States
- Permission denied: Show banner similar to System Data
- No containers directory: Show helpful message
- Calculation errors: Show "—" for size

## Future Enhancements UI

Potential UI additions:
- 📁 Right-click context menu for "Show in Finder"
- 🗑️ Delete button for orphaned containers
- 📊 Pie chart showing orphaned vs. installed
- 🔍 Search/filter by bundle ID
- 📤 Export list button
- ⚙️ Settings for automatic scanning
