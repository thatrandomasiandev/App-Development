import SwiftUI

enum ClipFilter: CaseIterable, Identifiable {
    case all, text, images, snippets

    var id: Self { self }

    var icon: String {
        switch self {
        case .all:      return "tray"
        case .text:     return "doc.plaintext"
        case .images:   return "photo"
        case .snippets: return "pin"
        }
    }
}

