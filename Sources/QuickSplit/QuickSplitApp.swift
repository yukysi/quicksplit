import SwiftUI
import AppKit
import Sparkle

@main
struct QuickSplitApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        Settings {
            SettingsView()
        }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?
    private var settingsWindowController: NSWindowController?
    private var updaterController: SPUStandardUpdaterController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        updaterController = SPUStandardUpdaterController(startingUpdater: true, updaterDelegate: nil, userDriverDelegate: nil)
        #if DEBUG
        if ScreenshotRenderer.runIfRequested() {
            NSApp.terminate(nil)
            return
        }
        #endif
        NSApp.setActivationPolicy(.accessory)
        installStatusItem()
        Task { @MainActor in
            ShortcutRegistry.registerAll()
            AccessibilityGuard.shared.refresh()
        }
    }

    private func installStatusItem() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = item.button {
            let image = NSImage(systemSymbolName: "rectangle.split.2x2",
                                accessibilityDescription: "QuickSplit")
            image?.isTemplate = true
            button.image = image
            button.target = self
            button.action = #selector(statusItemClicked(_:))
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
        statusItem = item
    }

    @objc private func statusItemClicked(_ sender: Any?) {
        showSettings()
    }

    private func showSettings() {
        if settingsWindowController == nil {
            let hosting = NSHostingController(rootView: SettingsView(checkForUpdates: { [weak self] in
                self?.updaterController?.checkForUpdates(nil)
            }))
            let window = NSWindow(contentViewController: hosting)
            window.title = "QuickSplit"
            window.styleMask = [.titled, .closable, .miniaturizable]
            window.setContentSize(NSSize(width: 420, height: 380))
            window.isReleasedWhenClosed = false
            window.center()
            settingsWindowController = NSWindowController(window: window)
        }
        NSApp.activate(ignoringOtherApps: true)
        settingsWindowController?.showWindow(nil)
        settingsWindowController?.window?.makeKeyAndOrderFront(nil)
    }
}
