import AppKit
import ApplicationServices
import Combine

@MainActor
final class AccessibilityGuard: ObservableObject {
    static let shared = AccessibilityGuard()

    @Published private(set) var isTrusted: Bool = false
    @Published private(set) var hasInputMonitoring: Bool = false
    private var timer: Timer?

    private init() {
        refresh()
    }

    func refresh() {
        let wasBothGranted = isTrusted && hasInputMonitoring
        isTrusted = AXIsProcessTrusted()
        hasInputMonitoring = EiKanaManager.hasInputMonitoringAccess
        if isTrusted, hasInputMonitoring, !wasBothGranted {
            // 両方の権限が揃った瞬間に、起動時点で失敗していた EiKanaManager のタップ生成を再試行する
            EiKanaManager.shared.start()
        }
    }

    func requestTrust() {
        let key = "AXTrustedCheckOptionPrompt" as CFString
        let options = [key: true] as CFDictionary
        isTrusted = AXIsProcessTrustedWithOptions(options)
        if !hasInputMonitoring {
            CGRequestListenEventAccess()
        }
        startMonitoring()
    }

    func openSystemSettings() {
        // 一度もプロンプトを要求していないと、macOS のアクセシビリティ一覧に
        // このアプリ自体が登録されずトグルする対象が現れない。先に登録/プロンプトを
        // 発行してから設定画面を開く。
        requestTrust()
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
        NSWorkspace.shared.open(url)
    }

    func openInputMonitoringSettings() {
        if !hasInputMonitoring {
            CGRequestListenEventAccess()
        }
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ListenEvent")!
        NSWorkspace.shared.open(url)
        startMonitoring()
    }

    private func startMonitoring() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self else { return }
                self.refresh()
                if self.isTrusted, self.hasInputMonitoring {
                    self.timer?.invalidate()
                    self.timer = nil
                }
            }
        }
    }
}
