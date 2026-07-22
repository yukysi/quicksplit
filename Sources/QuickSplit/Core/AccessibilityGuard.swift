import AppKit
import ApplicationServices
import Combine

@MainActor
final class AccessibilityGuard: ObservableObject {
    static let shared = AccessibilityGuard()

    @Published private(set) var isTrusted: Bool = false
    private var timer: Timer?

    private init() {
        refresh()
    }

    func refresh() {
        let wasTrusted = isTrusted
        isTrusted = AXIsProcessTrusted()
        if isTrusted, !wasTrusted {
            // 権限が付与された瞬間に、起動時点で失敗していた EiKanaManager のタップ生成を再試行する
            EiKanaManager.shared.start()
        }
    }

    func requestTrust() {
        let key = "AXTrustedCheckOptionPrompt" as CFString
        let options = [key: true] as CFDictionary
        isTrusted = AXIsProcessTrustedWithOptions(options)
        startMonitoring()
    }

    func openSystemSettings() {
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
        NSWorkspace.shared.open(url)
        startMonitoring()
    }

    private func startMonitoring() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self else { return }
                self.refresh()
                if self.isTrusted {
                    self.timer?.invalidate()
                    self.timer = nil
                }
            }
        }
    }
}
