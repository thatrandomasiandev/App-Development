import Foundation
import SwiftUI
import UniformTypeIdentifiers

final class ClipboardExportDocument: FileDocument, Sendable {
    static var readableContentTypes: [UTType] { [.json] }

    let export: ClipboardExport

    // Convert from your SwiftData model to the export struct
    init(clips: [ClipboardItem]) {
        let exportItems = clips.map { ClipboardExportItem(from: $0) }
        let String = "1.0"
        
        
        self.export = ClipboardExport(version: String, exportDate: Date(), clips: exportItems)
    }

    // For loading from file
    init(configuration: ReadConfiguration) throws {
        let data = configuration.file.regularFileContents ?? Data()
        let String = "1.0"
        
        self.export = (try? JSONDecoder().decode(ClipboardExport.self, from: data)) ?? ClipboardExport(version: String, exportDate: Date(), clips: [])
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let data = try JSONEncoder().encode(export)
        return FileWrapper(regularFileWithContents: data)
    }
}
