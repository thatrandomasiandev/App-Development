import SwiftUI
import AppKit

struct ClipTile: View {
    @EnvironmentObject var monitor: PasteboardMonitor
    let clip: ClipboardItem

    var body: some View {
        Button(action: pasteToClipboard) {
            HStack(spacing: 8) {
                SourceIcon(bundleID: clip.sourceAppBundleID)

                if let data = clip.imageData,
                   let nsImg = NSImage(data: data)
                {
                    Image(nsImage: nsImg)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(minHeight: 120)
                        .clipped()
                        .cornerRadius(12)
                        .shadow(radius: 4)
                } else {
                    ClipCardView(clip: clip)
                }
            }
        }
        .buttonStyle(.plain)
    }

    private func pasteToClipboard() {
        let pb = NSPasteboard.general
        pb.clearContents()

        if let data = clip.imageData,
           let nsImg = NSImage(data: data)
        {
            // Use high‐level API for images
            pb.writeObjects([nsImg])
        } else if let text = clip.text {
            // Use high‐level API for text
            pb.setString(text, forType: .string)
        }
    }
}

