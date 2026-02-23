import SwiftUI

struct ReviewDeleteView: View {
    @EnvironmentObject var deletionManager: DeletionManager
    @State private var showDeleteConfirmation = false
    @State private var deletionCompleted = false

    private var sortedItems: [DeletionItem] {
        Array(deletionManager.selectedItems.values).sorted { $0.name < $1.name }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Review & Delete")
                    .font(.title2)
                    .fontWeight(.semibold)

                Spacer()

                if deletionManager.itemCount > 0 {
                    VStack(alignment: .trailing, spacing: 1) {
                        Text("\(deletionManager.itemCount) item\(deletionManager.itemCount == 1 ? "" : "s")")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                        Text(deletionManager.formattedTotalSize)
                            .font(.system(size: 13, weight: .medium, design: .monospaced))
                            .foregroundColor(.red)
                    }

                    Button(action: { deletionManager.clearAll() }) {
                        Label("Clear All", systemImage: "xmark.circle")
                    }
                    .buttonStyle(.bordered)

                    Button(action: { showDeleteConfirmation = true }) {
                        Label("Move to Trash", systemImage: "trash")
                            .padding(.horizontal, 4)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.red)
                    .disabled(deletionManager.isDeleting)
                }
            }
            .padding()
            .background(Color(NSColor.windowBackgroundColor))

            Divider()

            // Content
            if deletionManager.itemCount == 0 {
                VStack(spacing: 20) {
                    Image(systemName: "trash")
                        .font(.system(size: 60))
                        .foregroundColor(.secondary)

                    Text("No items queued for deletion")
                        .font(.title3)
                        .foregroundColor(.secondary)

                    Text("Select orphaned containers from the App Containers tab to review them here")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ZStack {
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 0) {
                            ForEach(Array(sortedItems.enumerated()), id: \.element.id) { index, item in
                                DeletionItemRow(item: item, index: index) {
                                    deletionManager.remove(item.id)
                                }
                            }
                        }
                        .padding(.vertical, 8)
                    }

                    if deletionManager.isDeleting {
                        VStack(spacing: 12) {
                            ProgressView()
                                .scaleEffect(1.2)
                            Text("Moving to Trash…")
                                .font(.system(size: 13))
                                .foregroundColor(.secondary)
                        }
                        .padding(24)
                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
                        .shadow(radius: 8)
                    }
                }
            }

            // Status bar
            if deletionManager.itemCount > 0 {
                Divider()
                HStack(spacing: 8) {
                    Image(systemName: "trash")
                        .font(.system(size: 11))
                        .foregroundColor(.red)
                    Text("\(deletionManager.itemCount) item\(deletionManager.itemCount == 1 ? "" : "s")")
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
        .alert("Move to Trash?", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Move to Trash", role: .destructive) {
                Task {
                    _ = await deletionManager.deleteSelected()
                }
            }
        } message: {
            Text("The selected items will be moved to the Trash. Disk space will only be freed after you empty the Trash.")
        }
    }
}

// MARK: - Deletion Item Row

struct DeletionItemRow: View {
    let item: DeletionItem
    let index: Int
    let onRemove: () -> Void
    @State private var isHovered = false

    var body: some View {
        HStack(spacing: 8) {
            // Icon
            Image(systemName: "shippingbox.fill")
                .foregroundColor(.orange)
                .font(.system(size: 14))
                .frame(width: 22, height: 18)
                .padding(.leading, 12)

            // Name and details
            VStack(alignment: .leading, spacing: 2) {
                Text(item.name)
                    .font(.system(size: 13))
                    .foregroundColor(.primary)
                    .lineLimit(1)

                Text(item.bundleID)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                    .lineLimit(1)

                Text(item.path)
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            // Size
            Text(item.formattedSize)
                .font(.system(size: 12, design: .monospaced))
                .foregroundColor(.secondary)

            // Remove button
            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
            .padding(.trailing, 4)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(rowBackground(index: index, isHovered: isHovered))
        .onHover { hovering in
            isHovered = hovering
        }
        .contentShape(Rectangle())
    }
}

#Preview {
    ReviewDeleteView()
        .environmentObject(DeletionManager())
}
