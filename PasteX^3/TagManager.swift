import Foundation
import SwiftData

class TagManager: ObservableObject {
    static let shared = TagManager()
    
    @Published var allTags: Set<String> = []
    
    private init() {}
    
    func updateTags(from clips: [ClipboardItem]) {
        var tags: Set<String> = []
        for clip in clips {
            tags.formUnion(clip.tags)
        }
        allTags = tags
    }
    
    func addTag(_ tag: String, to clip: ClipboardItem) {
        if !clip.tags.contains(tag) {
            clip.tags.append(tag)
            allTags.insert(tag)
        }
    }
    
    func removeTag(_ tag: String, from clip: ClipboardItem) {
        clip.tags.removeAll { $0 == tag }
        
        // Remove from allTags if no other clips use it
        let clipsUsingTag = clip.tags.contains { $0 == tag }
        if !clipsUsingTag {
            allTags.remove(tag)
        }
    }
    
    func getClipsWithTag(_ tag: String, from clips: [ClipboardItem]) -> [ClipboardItem] {
        return clips.filter { $0.tags.contains(tag) }
    }
    
    func getPopularTags(from clips: [ClipboardItem], limit: Int = 10) -> [String] {
        var tagCounts: [String: Int] = [:]
        
        for clip in clips {
            for tag in clip.tags {
                tagCounts[tag, default: 0] += 1
            }
        }
        
        return tagCounts.sorted { $0.value > $1.value }
            .prefix(limit)
            .map { $0.key }
    }
} 
