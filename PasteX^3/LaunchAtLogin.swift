import Foundation
import ServiceManagement

@MainActor
final class LaunchAtLoginManager: ObservableObject, Sendable {
    @Published var isEnabled: Bool = false
    
    init() {
        checkLaunchAtLoginStatus()
    }
    
    func checkLaunchAtLoginStatus() {
        if #available(macOS 14.0, *) {
            let status = SMAppService.mainApp.status
            self.isEnabled = status == .enabled
        } else {
            // Fallback for older macOS versions
            let bundleIdentifier = Bundle.main.bundleIdentifier ?? ""
            let loginItems = SMCopyAllJobDictionaries(kSMDomainUserLaunchd).takeRetainedValue() as? [[String: Any]] ?? []
            isEnabled = loginItems.contains { item in
                (item["Label"] as? String) == bundleIdentifier
            }
        }
    }
    
    func toggleLaunchAtLogin() {
        if #available(macOS 14.0, *) {
            let service = SMAppService.mainApp
            let status = service.status
            if status == .enabled {
                try? service.unregister()
            } else {
                try? service.register()
            }
            self.checkLaunchAtLoginStatus()
        } else {
            // Fallback for older macOS versions
            let bundleIdentifier = Bundle.main.bundleIdentifier ?? ""
            if isEnabled {
                // Remove from login items
                let script = """
                tell application \"System Events\"
                    delete login item \"\(bundleIdentifier)\"
                end tell
                """
                let appleScript = NSAppleScript(source: script)
                appleScript?.executeAndReturnError(nil)
            } else {
                // Add to login items
                let script = """
                tell application \"System Events\"
                    make login item at end with properties {path:\"\(Bundle.main.bundlePath)\", hidden:true}
                end tell
                """
                let appleScript = NSAppleScript(source: script)
                appleScript?.executeAndReturnError(nil)
            }
            checkLaunchAtLoginStatus()
        }
    }
} 
