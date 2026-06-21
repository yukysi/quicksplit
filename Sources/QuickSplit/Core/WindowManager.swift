import AppKit
import ApplicationServices
import os

@MainActor
final class WindowManager {
    static let shared = WindowManager()

    private let logger = Logger(subsystem: "com.yukiyasui.quicksplit", category: "WindowManager")
    private var frameHistory: [CGRect] = []
    private let historyLimit = 20

    private init() {}

    func perform(_ action: WindowAction) {
        if !AccessibilityGuard.shared.isTrusted {
            AccessibilityGuard.shared.refresh()
            if !AccessibilityGuard.shared.isTrusted {
                AccessibilityGuard.shared.requestTrust()
                logger.warning("Accessibility permission is not granted; requested trust prompt.")
                return
            }
        }

        guard let app = NSWorkspace.shared.frontmostApplication else { return }
        let appElement = AXUIElementCreateApplication(app.processIdentifier)

        var windowRef: CFTypeRef?
        let err = AXUIElementCopyAttributeValue(appElement, kAXFocusedWindowAttribute as CFString, &windowRef)
        guard err == .success else {
            logger.error("Failed to copy focused window attribute: \(err.rawValue)")
            return
        }
        guard let unwrapped = windowRef else { return }
        let window = unwrapped as! AXUIElement

        guard let currentFrame = frame(of: window) else { return }

        if action == .restore {
            if let last = frameHistory.popLast() {
                setFrame(last, of: window)
            }
            return
        }

        let screen = screenContaining(axFrame: currentFrame) ?? NSScreen.main
        guard let visibleFrame = screen?.visibleFrame else { return }

        let target: CGRect
        if action == .center {
            target = WindowLayoutCalculator.centered(size: currentFrame.size, in: visibleFrame)
        } else if let computed = WindowLayoutCalculator.targetFrame(for: action, in: visibleFrame) {
            target = computed
        } else {
            return
        }

        pushHistory(currentFrame)

        let axTarget = axRect(fromBottomLeft: target)
        setFrame(axTarget, of: window)
    }

    private func pushHistory(_ frame: CGRect) {
        frameHistory.append(frame)
        if frameHistory.count > historyLimit {
            frameHistory.removeFirst(frameHistory.count - historyLimit)
        }
    }

    private func frame(of window: AXUIElement) -> CGRect? {
        var posRef: CFTypeRef?
        var sizeRef: CFTypeRef?
        let positionErr = AXUIElementCopyAttributeValue(window, kAXPositionAttribute as CFString, &posRef)
        guard positionErr == .success else {
            logger.error("Failed to copy window position attribute: \(positionErr.rawValue)")
            return nil
        }

        let sizeErr = AXUIElementCopyAttributeValue(window, kAXSizeAttribute as CFString, &sizeRef)
        guard sizeErr == .success else {
            logger.error("Failed to copy window size attribute: \(sizeErr.rawValue)")
            return nil
        }

        guard let posRef, let sizeRef else { return nil }

        var position = CGPoint.zero
        var size = CGSize.zero
        AXValueGetValue(posRef as! AXValue, .cgPoint, &position)
        AXValueGetValue(sizeRef as! AXValue, .cgSize, &size)
        return CGRect(origin: position, size: size)
    }

    private func setFrame(_ frame: CGRect, of window: AXUIElement) {
        var position = frame.origin
        var size = frame.size
        if let posValue = AXValueCreate(.cgPoint, &position) {
            let err = AXUIElementSetAttributeValue(window, kAXPositionAttribute as CFString, posValue)
            if err != .success {
                logger.error("Failed to set initial window position: \(err.rawValue)")
            }
        }
        if let sizeValue = AXValueCreate(.cgSize, &size) {
            let err = AXUIElementSetAttributeValue(window, kAXSizeAttribute as CFString, sizeValue)
            if err != .success {
                logger.error("Failed to set window size: \(err.rawValue)")
            }
        }
        // 一部アプリはリサイズ時に位置をクランプするため、
        // サイズ確定後に同じ位置を再適用して狙った着地点へ戻す。
        if let posValue = AXValueCreate(.cgPoint, &position) {
            let err = AXUIElementSetAttributeValue(window, kAXPositionAttribute as CFString, posValue)
            if err != .success {
                logger.error("Failed to set final window position: \(err.rawValue)")
            }
        }
    }

    // AX uses top-left origin across the global screen space (primary screen's top).
    // NSScreen uses bottom-left origin of primary screen. Convert.
    private func axRect(fromBottomLeft rect: CGRect) -> CGRect {
        guard let primary = NSScreen.screens.first else { return rect }
        let primaryHeight = primary.frame.height
        return CGRect(
            x: rect.origin.x,
            y: primaryHeight - rect.origin.y - rect.height,
            width: rect.width,
            height: rect.height
        )
    }

    private func bottomLeftRect(fromAX rect: CGRect) -> CGRect {
        guard let primary = NSScreen.screens.first else { return rect }
        let primaryHeight = primary.frame.height
        return CGRect(
            x: rect.origin.x,
            y: primaryHeight - rect.origin.y - rect.height,
            width: rect.width,
            height: rect.height
        )
    }

    private func screenContaining(axFrame: CGRect) -> NSScreen? {
        let bl = bottomLeftRect(fromAX: axFrame)
        let center = CGPoint(x: bl.midX, y: bl.midY)
        return NSScreen.screens.first(where: { $0.frame.contains(center) }) ?? NSScreen.screens.first
    }
}
