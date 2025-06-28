import Foundation
import SwiftData
import AppKit

struct ClipboardExport: Codable {
    let version: String
    let exportDate: Date
    let clips: [ClipboardExportItem]
}

struct ClipboardExportItem: Codable {
    let id: UUID
    let text: String?
    let imageData: Data?
    let date: Date
    let isPinned: Bool
    let sourceAppBundleID: String?
    let type: String
    let tags: [String]
    let isFavorite: Bool
    let lastUsed: Date?
    
    init(from clip: ClipboardItem) {
        self.id = clip.id
        self.text = clip.text
        self.imageData = clip.imageData
        self.date = clip.date
        self.isPinned = clip.isPinned
        self.sourceAppBundleID = clip.sourceAppBundleID
        self.type = clip.type.rawValue
        self.tags = clip.tags
        self.isFavorite = clip.isFavorite
        self.lastUsed = clip.lastUsed
    }
}

class ClipboardExporter {
    static func exportClips(_ clips: [ClipboardItem]) -> Data? {
        let exportItems = clips.map { ClipboardExportItem(from: $0) }
        let export = ClipboardExport(version: "1.0", exportDate: Date(), clips: exportItems)
        
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            return try encoder.encode(export)
        } catch {
            print("Export error: \(error)")
            return nil
        }
    }
    
    static func importClips(from data: Data, context: ModelContext) -> Bool {
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let export = try decoder.decode(ClipboardExport.self, from: data)
            
            for exportItem in export.clips {
                let clip = ClipboardItem(
                    id: exportItem.id,
                    text: exportItem.text,
                    imageData: exportItem.imageData,
                    date: exportItem.date,
                    isPinned: exportItem.isPinned,
                    sourceAppBundleID: exportItem.sourceAppBundleID,
                    type: ClipType(rawValue: exportItem.type) ?? .text,
                    fileURLs: nil, // Files would need special handling
                    tags: exportItem.tags,
                    isFavorite: exportItem.isFavorite,
                    lastUsed: exportItem.lastUsed
                )
                context.insert(clip)
            }
            
            try context.save()
            return true
        } catch {
            print("Import error: \(error)")
            return false
        }
    }
    
    static func exportToFile(_ clips: [ClipboardItem], url: URL) -> Bool {
        guard let data = exportClips(clips) else { return false }
        
        do {
            try data.write(to: url)
            return true
        } catch {
            print("File export error: \(error)")
            return false
        }
    }
    
    static func importFromFile(url: URL, context: ModelContext) -> Bool {
        do {
            let data = try Data(contentsOf: url)
            return importClips(from: data, context: context)
        } catch {
            print("File import error: \(error)")
            return false
        }
    }
} 
