//Clip-Card/PasteX^2


import SwiftUI
import AppKit

struct ClipCardView: View {
    let clip: ClipboardItem

    var body: some View {
        Button(action: pasteToClipboard) {
            VStack(alignment: .leading, spacing: 8) {
                if let data = clip.imageData, let nsImg = NSImage(data: data) {
                    Image(nsImage: nsImg)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: 100)
                        .cornerRadius(8)
                        .shadow(radius: 3)
                }
                if let text = clip.text, !text.isEmpty {
                    Text(text)
                        .lineLimit(8)
                        .font(.body)
                        .foregroundStyle(.primary)
                        .padding(.top, clip.imageData != nil ? 4 : 0)
                }
            }
            .frame(minWidth: 160, maxWidth: .infinity, minHeight: 110, maxHeight: 170, alignment: .topLeading)
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(.thinMaterial)
                    .shadow(radius: 2)
            )
        }
        .buttonStyle(.plain) // Keeps your design looking like a card, not a default button
    }

    private func pasteToClipboard() {
        let pb = NSPasteboard.general
        pb.clearContents()
        if let data = clip.imageData, let nsImg = NSImage(data: data) {
            pb.writeObjects([nsImg])
        } else if let text = clip.text {
            pb.setString(text, forType: .string)
        }
    }
}

