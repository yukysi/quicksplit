import SwiftUI
import AppKit

@main
struct QuickSplitApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        MenuBarExtra {
            MenuBarPopoverView()
        } label: {
            Image(systemName: "rectangle.split.2x2")
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView()
        }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        Task { @MainActor in
            ShortcutRegistry.registerAll()
            AccessibilityGuard.shared.refresh()
        }
    }
}
