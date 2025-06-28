import SwiftUI
import SwiftData

@main
struct PasteXApp: App {
    // 1) Wire up your AppDelegate for the status-item/hotkey bits
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    // 2) Create your SwiftData container
    let modelContainer = try! ModelContainer(for: ClipboardItem.self)

    // 3) Make your PasteboardMonitor once, and hand it to AppDelegate + ContentView
    @StateObject private var monitor: PasteboardMonitor
    @StateObject private var tagManager = TagManager.shared

    init() {
        let ctx = modelContainer.mainContext
        _monitor = StateObject(wrappedValue: PasteboardMonitor(context: ctx))
        appDelegate.monitor        = _monitor.wrappedValue
        appDelegate.modelContainer = modelContainer
        
        // Initialize notification system
        NotificationManager.shared.setupNotificationCategories()
        
        // Set up auto-cleanup timer
        setupAutoCleanup()
    }
    
    private func setupAutoCleanup() {
        Timer.scheduledTimer(withTimeInterval: 3600, repeats: true) { _ in // Run every hour
            let autoCleanup = UserDefaults.standard.bool(forKey: "autoCleanup")
            if autoCleanup {
                monitor.cleanupOldClips()
            }
        }
    }

    var body: some Scene {
        // 4) Your popover/main window
        WindowGroup {
            ContentView()
                .environmentObject(monitor)
                .environmentObject(tagManager)
        }

        // 5) Your Preferences/Settings scene
        Settings {
            PreferencesView()
                // ← **This is critical**—inject the SwiftData context here!
                .environment(\.modelContext, modelContainer.mainContext)
        }
        .modelContainer(modelContainer)  // also attach it globally
    }
}


