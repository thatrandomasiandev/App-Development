import Cocoa
import SwiftUI
import SwiftData

final class PreferencesWindowController: NSWindowController {
    static let shared: PreferencesWindowController = {
        let appDel    = NSApp.delegate as! AppDelegate
        let container = appDel.modelContainer!

        let prefsView = PreferencesView()
            .environment(\.modelContext, container.mainContext)

        let hosting = NSHostingController(rootView: prefsView)
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 650, height: 450),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered, defer: false
        )
        window.title                 = "Preferences"
        window.contentViewController = hosting
        window.center()
        window.isReleasedWhenClosed  = false

        return PreferencesWindowController(window: window)
    }()

    func show() {
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}

