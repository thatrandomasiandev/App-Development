import Cocoa
import SwiftUI
import SwiftData
import HotKey

final class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?
    var popover: NSPopover!
    var hotKey: HotKey!
    var monitor: PasteboardMonitor!
    var modelContainer: ModelContainer!

    func applicationDidFinishLaunching(_ notification: Notification) {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(updateMenuBarIcon),
            name: .showInMenuBarChanged,
            object: nil
        )
        updateMenuBarIcon()

        let contentView = ContentView().environmentObject(monitor)
        let hosting    = NSHostingController(rootView: contentView)
        popover        = NSPopover()
        popover.behavior            = .transient
        popover.contentSize         = NSSize(width: 360, height: 500)
        popover.contentViewController = hosting

        hotKey = HotKey(key: .v, modifiers: [.command, .shift])
        hotKey.keyDownHandler = { [weak self] in self?.togglePopover(nil) }
    }

    @objc private func updateMenuBarIcon() {
        let show = UserDefaults.standard.bool(forKey: "showInMenuBar")
        if show {
            if statusItem == nil {
                statusItem = NSStatusBar.system.statusItem(
                    withLength: NSStatusItem.variableLength
                )
                if let btn = statusItem?.button {
                    btn.image   = NSImage(
                        systemSymbolName: "clipboard",
                        accessibilityDescription: "PasteX"
                    )
                    btn.action  = #selector(togglePopover(_:))
                    btn.target  = self
                }
            }
        } else if let item = statusItem {
            NSStatusBar.system.removeStatusItem(item)
            statusItem = nil
        }
    }

    @objc private func togglePopover(_ sender: Any?) {
        guard let btn = statusItem?.button else { return }
        if popover.isShown {
            popover.performClose(sender)
        } else {
            popover.show(
                relativeTo: btn.bounds,
                of: btn,
                preferredEdge: .minY
            )
            popover.contentViewController?.view.window?.becomeKey()
        }
    }
}

