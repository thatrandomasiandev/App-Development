import Foundation
import SwiftData
// In your ClipboardItem.swift file (or wherever ClipboardItem is defined)
 // Make sure Foundation is imported if using Data or String
// import CoreGraphics or other frameworks if your ClipboardItem uses types from them
// For example, if ClipboardItem internally uses NSImage or UIImage, you'd need AppKit/UIKit.
// However, the `isContentIdentical` only directly uses Data and String, which are Foundation types.


extension ClipboardItem {
    func isContentIdentical(to other: ClipboardItem) -> Bool {
        // Check if both have text and compare
        if let selfText = self.text, let otherText = other.text {
            // If both have text, check if text is identical AND neither has image data
            // This prevents a text-only item from being considered identical to a text-and-image item
            return selfText == otherText && self.imageData == nil && other.imageData == nil
        }

        // Check if both have image data and compare
        if let selfImageData = self.imageData, let otherImageData = other.imageData {
            // If both have image data, check if image data is identical AND neither has text
            // This prevents an image-only item from being considered identical to an image-and-text item
            return selfImageData == otherImageData && self.text == nil && other.text == nil
        }

        // This handles cases where:
        // - Both are nil (empty content) -> true (considered identical)
        // - One is text-only and the other is image-only -> false (not identical)
        // - One is nil and the other has content -> false (not identical)
        return self.text == nil && other.text == nil && self.imageData == nil && other.imageData == nil
    }
}
@Model
final class ClipboardItem: Identifiable {
    @Attribute(.unique) var id: UUID
    var text: String?
    var imageData: Data?
    var date: Date
    var isPinned: Bool
    var sourceAppBundleID: String?

    /// You must initialize *all* of your persisted properties here,
    /// with whatever defaults you need.
    init(
        id: UUID = .init(),
        text: String? = nil,
        imageData: Data? = nil,
        date: Date = .init(),
        isPinned: Bool = false,
        sourceAppBundleID: String? = nil
    ) {
        self.id                = id
        self.text              = text
        self.imageData         = imageData
        self.date              = date
        self.isPinned          = isPinned
        self.sourceAppBundleID = sourceAppBundleID
    }
}

