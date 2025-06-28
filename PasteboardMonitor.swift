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

        // 1) Try PNG
        if let pngData = pb.data(forType: .png) {
            let clip = ClipboardItem(
                id: UUID(),
                text: nil,
                imageData: pngData,
                date: Date(),
                isPinned: false,
                sourceAppBundleID: frontApp
            )
            saveAndInsert(clip)
            return
        }
        // 2) Try TIFF
        if let tiffData = pb.data(forType: .tiff) {
            let clip = ClipboardItem(
                id: UUID(),
                text: nil,
                imageData: tiffData,
                date: Date(),
                isPinned: false,
                sourceAppBundleID: frontApp
            )
            saveAndInsert(clip)
            return
        }
        // 3) Fallback to text
        if let str = pb.string(forType: .string), !str.isEmpty {
            let clip = ClipboardItem(
                id: UUID(),
                text: str,
                imageData: nil,
                date: Date(),
                isPinned: false,
                sourceAppBundleID: frontApp
            )
            saveAndInsert(clip)
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

    func deleteClip(_ clip: ClipboardItem) {
        context.delete(clip)
        try? context.save()
        items.removeAll { $0.id == clip.id }
    }
}

