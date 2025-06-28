import SwiftUI
import AppKit

struct SourceIcon: View {
    let bundleID: String?

    // Compute the NSImage once, before building the view
    private var iconImage: NSImage {
        if let id = bundleID,
           let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: id) {
            let img = NSWorkspace.shared.icon(forFile: url.path)
            img.size = NSSize(width: 24, height: 24)
            return img
        } else {
            // Use an SF Symbol as fallback
            return NSImage(
                systemSymbolName: "questionmark.app",
                accessibilityDescription: "Unknown App"
            )!
        }
    }

    var body: some View {
        Image(nsImage: iconImage)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: 24, height: 24)
            .cornerRadius(4)
            .foregroundStyle(bundleID == nil ? .secondary : .primary)
    }
}

