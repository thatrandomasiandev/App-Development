import Foundation
import UserNotifications
import AppKit

class NotificationManager: ObservableObject {
    static let shared = NotificationManager()
    
    private init() {
        requestPermission()
    }
    
    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("Notification permission granted")
            } else if let error = error {
                print("Notification permission error: \(error)")
            }
        }
    }
    
    func showClipAddedNotification(for clip: ClipboardItem) {
        let soundEffects = UserDefaults.standard.bool(forKey: "soundEffects")
        
        let content = UNMutableNotificationContent()
        content.title = "New Clip Added"
        
        if let text = clip.text {
            let preview = text.count > 50 ? String(text.prefix(50)) + "..." : text
            content.body = preview
        } else if clip.isImageClip {
            content.body = "Image copied to clipboard"
        } else if clip.isFileClip {
            content.body = "\(clip.fileCount) file(s) copied to clipboard"
        } else {
            content.body = "Content copied to clipboard"
        }
        
        content.sound = soundEffects ? .default : nil
        content.categoryIdentifier = "CLIP_ADDED"
        
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Notification error: \(error)")
            }
        }
    }
    
    func setupNotificationCategories() {
        let viewAction = UNNotificationAction(
            identifier: "VIEW_CLIP",
            title: "View",
            options: [.foreground]
        )
        
        let category = UNNotificationCategory(
            identifier: "CLIP_ADDED",
            actions: [viewAction],
            intentIdentifiers: [],
            options: []
        )
        
        UNUserNotificationCenter.current().setNotificationCategories([category])
    }
} 
