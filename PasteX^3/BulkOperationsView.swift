import SwiftUI

struct BulkOperationsView: View {
    @EnvironmentObject var monitor: PasteboardMonitor
    @Binding var selectedClips: Set<ClipboardItem>
    @Binding var isSelectionMode: Bool
    
    var body: some View {
        HStack {
            Text("\(selectedClips.count) selected")
                .font(.caption)
                .foregroundStyle(.secondary)
            
            Spacer()
            
            HStack(spacing: 8) {
                Button("Pin All") {
                    monitor.pinMultipleClips(Array(selectedClips), pin: true)
                    selectedClips.removeAll()
                    isSelectionMode = false
                }
                .disabled(selectedClips.isEmpty)
                
                Button("Unpin All") {
                    monitor.pinMultipleClips(Array(selectedClips), pin: false)
                    selectedClips.removeAll()
                    isSelectionMode = false
                }
                .disabled(selectedClips.isEmpty)
                
                Button("Favorite All") {
                    selectedClips.forEach { clip in
                        if !clip.isFavorite {
                            monitor.toggleFavorite(clip)
                        }
                    }
                    selectedClips.removeAll()
                    isSelectionMode = false
                }
                .disabled(selectedClips.isEmpty)
                
                Button("Delete All", role: .destructive) {
                    monitor.deleteMultipleClips(Array(selectedClips))
                    selectedClips.removeAll()
                    isSelectionMode = false
                }
                .disabled(selectedClips.isEmpty)
                
                Button("Cancel") {
                    selectedClips.removeAll()
                    isSelectionMode = false
                }
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial)
        .cornerRadius(8)
        .padding(.horizontal)
    }
} 
