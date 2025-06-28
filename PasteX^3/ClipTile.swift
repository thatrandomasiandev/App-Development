import SwiftUI
import AppKit

struct ClipTile: View {
    @EnvironmentObject var monitor: PasteboardMonitor
    @EnvironmentObject var tagManager: TagManager
    let clip: ClipboardItem
    @State private var isHovered = false
    @State private var showingTagEditor = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            header
            content
            footer
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.regularMaterial)
                .shadow(radius: isHovered ? 8 : 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(clip.isPinned ? .orange : .clear, lineWidth: 2)
        )
        .scaleEffect(isHovered ? 1.02 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHovered)
        .onHover { hovering in
            isHovered = hovering
        }
        .onTapGesture {
            monitor.pasteClip(clip)
        }
        .contextMenu {
            Button(clip.isPinned ? "Unpin" : "Pin") {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    monitor.togglePin(clip)
                }
            }
            
            Button(clip.isFavorite ? "Remove from Favorites" : "Add to Favorites") {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    monitor.toggleFavorite(clip)
                }
            }
            
            if clip.text != nil {
                Button("Copy as Plain Text") {
                    monitor.pasteClipAsPlainText(clip)
                }
            }
            
            Divider()
            
            Button("Add Tag...") {
                showingTagEditor = true
            }
            
            Divider()
            
            Button("Delete", role: .destructive) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    monitor.deleteClip(clip)
                }
            }
        }
        .sheet(isPresented: $showingTagEditor) {
            TagEditView(clip: clip, isPresented: $showingTagEditor)
                .environmentObject(monitor)
                .environmentObject(tagManager)
        }
    }

    private var header: some View {
        HStack {
            SourceIcon(bundleID: clip.sourceAppBundleID)
                .frame(width: 16, height: 16)
            Spacer()
            Image(systemName: clip.type.icon)
                .font(.caption)
                .foregroundStyle(.secondary)
            if clip.isPinned {
                Image(systemName: "pin.fill")
                    .font(.caption)
                    .foregroundStyle(.orange)
            }
            if clip.isFavorite {
                Image(systemName: "heart.fill")
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        }
    }

    private var content: some View {
        Group {
            if clip.isImageClip {
                imageContent
            } else if clip.isFileClip {
                fileContent
            } else {
                textContent
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var footer: some View {
        HStack {
            Text(clip.date, style: .relative)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Spacer()
            if !clip.tags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 4) {
                        ForEach(clip.tags.prefix(3), id: \ .self) { tag in
                            Text(tag)
                                .font(.caption2)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(.blue.opacity(0.2))
                                )
                                .foregroundStyle(.blue)
                        }
                        if clip.tags.count > 3 {
                            Text("+\(clip.tags.count - 3)")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var imageContent: some View {
        if let imageData = clip.imageData, let nsImg = NSImage(data: imageData) {
            Image(nsImage: nsImg)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(maxHeight: 120)
                .cornerRadius(8)
                .shadow(radius: 2)
        }
    }

    @ViewBuilder
    private var fileContent: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Image(systemName: "folder.fill")
                    .foregroundStyle(.blue)
                Text("\(clip.fileCount) file\(clip.fileCount == 1 ? "" : "s")")
                    .font(.caption)
                    .fontWeight(.medium)
            }
            if let text = clip.text {
                Text(text)
                    .font(.caption)
                    .lineLimit(3)
                    .foregroundStyle(.secondary)
            }
        }
    }

    @ViewBuilder
    private var textContent: some View {
        if let text = clip.text {
            Text(text)
                .font(.body)
                .lineLimit(6)
                .multilineTextAlignment(.leading)
        }
    }
}


