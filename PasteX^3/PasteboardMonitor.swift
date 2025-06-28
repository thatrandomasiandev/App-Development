import Foundation
import AppKit
import Combine
import SwiftData

class PasteboardMonitor: ObservableObject {
    @Published var items: [ClipboardItem] = []
    private let context: ModelContext
    private var lastChangeCount = NSPasteboard.general.changeCount
    private var timer: AnyCancellable?

    init(context: ModelContext) {
        self.context = context
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(updateRunState),
            name: .runInBackgroundChanged,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(clearHistory),
            name: .eraseHistory,
            object: nil
        )
        fetchSavedItems()
        updateRunState()
    }

    @objc private func updateRunState() {
        timer?.cancel()
        if true {
            timer = Timer.publish(every: 0.5, on: .main, in: .common)
                .autoconnect()
                .sink { [weak self] _ in self?.checkPasteboard() }
        }
    }

    private func checkPasteboard() {
        let pb = NSPasteboard.general
        guard pb.changeCount != lastChangeCount else { return }
        lastChangeCount = pb.changeCount
        let frontApp = NSWorkspace.shared.frontmostApplication?.bundleIdentifier

        // Check for duplicate content first
        let newClip = createClipboardItem(from: pb, sourceApp: frontApp)
        if let newClip = newClip, !isDuplicate(newClip) {
            saveAndInsert(newClip)
            
            // Post notification for new clip
            NotificationCenter.default.post(
                name: .newClipAdded,
                object: newClip
            )
            
            // Show system notification if enabled
            let showNotifications = UserDefaults.standard.bool(forKey: "showNotifications")
            if showNotifications {
                NotificationManager.shared.showClipAddedNotification(for: newClip)
            }
        }
    }
    
    private func createClipboardItem(from pasteboard: NSPasteboard, sourceApp: String?) -> ClipboardItem? {
        // 1) Try files first
        if let files = pasteboard.readObjects(forClasses: [NSURL.self], options: nil) as? [URL],
           !files.isEmpty {
            let fileURLs = files.filter { $0.isFileURL }
            if !fileURLs.isEmpty {
                return ClipboardItem(
                    text: fileURLs.map { $0.path }.joined(separator: "\n"),
                    imageData: nil,
                    date: Date(),
                    isPinned: false,
                    sourceAppBundleID: sourceApp,
                    type: .files,
                    fileURLs: fileURLs
                )
            }
        }
        
        // 2) Try PNG
        if let pngData = pasteboard.data(forType: .png) {
            return ClipboardItem(
                text: nil,
                imageData: pngData,
                date: Date(),
                isPinned: false,
                sourceAppBundleID: sourceApp,
                type: .image
            )
        }
        
        // 3) Try TIFF
        if let tiffData = pasteboard.data(forType: .tiff) {
            return ClipboardItem(
                text: nil,
                imageData: tiffData,
                date: Date(),
                isPinned: false,
                sourceAppBundleID: sourceApp,
                type: .image
            )
        }
        
        // 4) Try rich text
        if let rtfData = pasteboard.data(forType: .rtf) {
            return ClipboardItem(
                text: pasteboard.string(forType: .string),
                imageData: rtfData,
                date: Date(),
                isPinned: false,
                sourceAppBundleID: sourceApp,
                type: .richText
            )
        }
        
        // 5) Try HTML
        if let htmlData = pasteboard.data(forType: .html) {
            return ClipboardItem(
                text: pasteboard.string(forType: .string),
                imageData: htmlData,
                date: Date(),
                isPinned: false,
                sourceAppBundleID: sourceApp,
                type: .html
            )
        }
        
        // 6) Fallback to plain text
        if let str = pasteboard.string(forType: .string), !str.isEmpty {
            return ClipboardItem(
                text: str,
                imageData: nil,
                date: Date(),
                isPinned: false,
                sourceAppBundleID: sourceApp,
                type: .text
            )
        }
        
        return nil
    }
    
    private func isDuplicate(_ newClip: ClipboardItem) -> Bool {
        return items.contains { existingClip in
            existingClip.isContentIdentical(to: newClip)
        }
    }

    private func saveAndInsert(_ clip: ClipboardItem) {
        context.insert(clip)
        try? context.save()
        DispatchQueue.main.async {
            self.items.insert(clip, at: 0)
        }
    }

    private func fetchSavedItems() {
        let req = FetchDescriptor<ClipboardItem>()
        if let saved = try? context.fetch(req) {
            items = saved.sorted {
                if $0.isPinned != $1.isPinned {
                    return $0.isPinned && !$1.isPinned
                }
                return $0.date > $1.date
            }
        }
    }

    @objc private func clearHistory() {
        let all = (try? context.fetch(FetchDescriptor<ClipboardItem>())) ?? []
        all.forEach { context.delete($0) }
        try? context.save()
        DispatchQueue.main.async { self.items.removeAll() }
    }

    func togglePin(_ clip: ClipboardItem) {
        clip.isPinned.toggle()
        try? context.save()
        fetchSavedItems()
    }

    func toggleFavorite(_ clip: ClipboardItem) {
        clip.isFavorite.toggle()
        try? context.save()
        fetchSavedItems()
    }

    func deleteClip(_ clip: ClipboardItem) {
        context.delete(clip)
        try? context.save()
        items.removeAll { $0.id == clip.id }
    }
    
    // MARK: - Paste Methods
    
    func pasteClip(_ clip: ClipboardItem) {
        // Update last used
        clip.lastUsed = Date()
        try? context.save()
        
        let pb = NSPasteboard.general
        pb.clearContents()
        
        switch clip.type {
        case .files:
            if let fileURLs = clip.fileURLs {
                pb.writeObjects(fileURLs as [NSPasteboardWriting])
            }
        case .image:
            if let imageData = clip.imageData, let nsImg = NSImage(data: imageData) {
                pb.writeObjects([nsImg])
            }
        case .richText:
            if let rtfData = clip.imageData {
                pb.setData(rtfData, forType: .rtf)
            }
            if let text = clip.text {
                pb.setString(text, forType: .string)
            }
        case .html:
            if let htmlData = clip.imageData {
                pb.setData(htmlData, forType: .html)
            }
            if let text = clip.text {
                pb.setString(text, forType: .string)
            }
        case .text:
            if let text = clip.text {
                pb.setString(text, forType: .string)
            }
        }
        
        // Simulate paste after a short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.simulatePaste()
        }
    }
    
    func pasteClipAsPlainText(_ clip: ClipboardItem) {
        guard let text = clip.text else { return }
        
        // Update last used
        clip.lastUsed = Date()
        try? context.save()
        
        let pb = NSPasteboard.general
        pb.clearContents()
        pb.setString(text, forType: .string)
        
        // Simulate paste after a short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.simulatePaste()
        }
    }
    
    private func simulatePaste() {
        let source = CGEventSource(stateID: .combinedSessionState)
        let keyDown = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: true) // V key
        let keyUp = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: false)
        
        keyDown?.flags = .maskCommand
        keyUp?.flags = .maskCommand
        
        keyDown?.post(tap: .cghidEventTap)
        keyUp?.post(tap: .cghidEventTap)
    }
    
    // MARK: - Bulk Operations
    
    func deleteMultipleClips(_ clips: [ClipboardItem]) {
        clips.forEach { clip in
            context.delete(clip)
        }
        try? context.save()
        
        let clipIds = Set(clips.map { $0.id })
        items.removeAll { clipIds.contains($0.id) }
    }
    
    func pinMultipleClips(_ clips: [ClipboardItem], pin: Bool) {
        clips.forEach { clip in
            clip.isPinned = pin
        }
        try? context.save()
        fetchSavedItems()
    }
    
    // MARK: - Auto-cleanup
    
    func cleanupOldClips() {
        let historyDuration = UserDefaults.standard.double(forKey: "historyDuration")
        if historyDuration > 0 {
            let cutoffDate = Date().addingTimeInterval(-historyDuration * 24 * 60 * 60)
            let oldClips = items.filter { $0.date < cutoffDate && !$0.isPinned }
            deleteMultipleClips(oldClips)
        }
    }
}


