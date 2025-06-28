import SwiftUI

enum ClipFilter: CaseIterable, Identifiable {
    case all, text, images, files, richText, html, snippets, favorites, recent

    var id: Self { self }

    var icon: String {
        switch self {
        case .all:      return "tray"
        case .text:     return "doc.plaintext"
        case .images:   return "photo"
        case .files:    return "folder"
        case .richText: return "doc.richtext"
        case .html:     return "doc.html"
        case .snippets: return "pin"
        case .favorites: return "heart"
        case .recent:   return "clock"
        }
    }
    
    var displayName: String {
        switch self {
        case .all:      return "All"
        case .text:     return "Text"
        case .images:   return "Images"
        case .files:    return "Files"
        case .richText: return "Rich Text"
        case .html:     return "HTML"
        case .snippets: return "Pinned"
        case .favorites: return "Favorites"
        case .recent:   return "Recent"
        }
    }
    
    func matches(_ clip: ClipboardItem) -> Bool {
        switch self {
        case .all:
            return true
        case .text:
            return clip.isTextClip
        case .images:
            return clip.isImageClip
        case .files:
            return clip.isFileClip
        case .richText:
            return clip.isRichTextClip
        case .html:
            return clip.isHtmlClip
        case .snippets:
            return clip.isPinned
        case .favorites:
            return clip.isFavorite
        case .recent:
            // Show clips from last 24 hours
            return clip.date > Date().addingTimeInterval(-24 * 60 * 60)
        }
    }
}


