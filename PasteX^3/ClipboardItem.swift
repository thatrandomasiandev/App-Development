import Foundation
import SwiftData
// In your ClipboardItem.swift file (or wherever ClipboardItem is defined)
 // Make sure Foundation is imported if using Data or String
// import CoreGraphics or other frameworks if your ClipboardItem uses types from them
// For example, if ClipboardItem internally uses NSImage or UIImage, you'd need AppKit/UIKit.
// However, the `isContentIdentical` only directly uses Data and String, which are Foundation types.

enum ClipType: String, Codable, CaseIterable, Sendable {
    case text = "text"
    case image = "image"
    case files = "files"
    case richText = "richText"
    case html = "html"
    
    var displayName: String {
        switch self {
        case .text: return "Text"
        case .image: return "Image"
        case .files: return "Files"
        case .richText: return "Rich Text"
        case .html: return "HTML"
        }
    }
    
    var icon: String {
        switch self {
        case .text: return "doc.text"
        case .image: return "photo"
        case .files: return "folder"
        case .richText: return "doc.richtext"
        case .html: return "doc.html"
        }
    }
}

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
    
    var previewText: String {
        if let text = text {
            let maxLength = 100
            if text.count > maxLength {
                return String(text.prefix(maxLength)) + "..."
            }
            return text
        }
        return "No text content"
    }
    
    var fileCount: Int {
        return fileURLs?.count ?? 0
    }
    
    var isFileClip: Bool {
        return type == .files && fileCount > 0
    }
    
    var isImageClip: Bool {
        return type == .image && imageData != nil
    }
    
    var isTextClip: Bool {
        return type == .text && text != nil
    }
    
    var isRichTextClip: Bool {
        return type == .richText && imageData != nil
    }
    
    var isHtmlClip: Bool {
        return type == .html && imageData != nil
    }
}

@Model
final class ClipboardItem: Identifiable, Encodable {
    @Attribute(.unique) var id: UUID
    var text: String?
    var imageData: Data?
    var date: Date
    var isPinned: Bool
    var sourceAppBundleID: String?
    var type: ClipType
    var fileURLs: [URL]?
    var tags: [String]
    var isFavorite: Bool
    var lastUsed: Date?

    /// You must initialize *all* of your persisted properties here,
    /// with whatever defaults you need.
    init(
        id: UUID = .init(),
        text: String? = nil,
        imageData: Data? = nil,
        date: Date = .init(),
        isPinned: Bool = false,
        sourceAppBundleID: String? = nil,
        type: ClipType = .text,
        fileURLs: [URL]? = nil,
        tags: [String] = [],
        isFavorite: Bool = false,
        lastUsed: Date? = nil
    ) {
        self.id                = id
        self.text              = text
        self.imageData         = imageData
        self.date              = date
        self.isPinned          = isPinned
        self.sourceAppBundleID = sourceAppBundleID
        self.type              = type
        self.fileURLs          = fileURLs
        self.tags              = tags
        self.isFavorite        = isFavorite
        self.lastUsed          = lastUsed
    }
    
    // MARK: - Encodable
    enum CodingKeys: String, CodingKey {
        case id, text, imageData, date, isPinned, sourceAppBundleID, type, fileURLs, tags, isFavorite, lastUsed
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encodeIfPresent(text, forKey: .text)
        try container.encodeIfPresent(imageData, forKey: .imageData)
        try container.encode(date, forKey: .date)
        try container.encode(isPinned, forKey: .isPinned)
        try container.encodeIfPresent(sourceAppBundleID, forKey: .sourceAppBundleID)
        try container.encode(type, forKey: .type)
        try container.encodeIfPresent(fileURLs, forKey: .fileURLs)
        try container.encode(tags, forKey: .tags)
        try container.encode(isFavorite, forKey: .isFavorite)
        try container.encodeIfPresent(lastUsed, forKey: .lastUsed)
    }
}


