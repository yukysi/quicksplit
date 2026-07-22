import Foundation
import CoreGraphics
import Combine
import ApplicationServices

/// CGEventTap のコールバックは @convention(c) のグローバル関数でなければならず、
/// @MainActor に隔離された EiKanaManager のプロパティには直接触れられない。
/// そのため、コールバックが読み書きする状態(押下中の修飾キー・保留中のトリガーキー・
/// 割り込みフラグ)と、tap 起動時点の keycode 設定のスナップショットをこの非隔離な
/// 箱クラスに閉じ込め、refcon 経由で受け渡す。
private final class EiKanaTapState {
    let eisuKeyCode: Int64
    let kanaKeyCode: Int64

    var eventTap: CFMachPort?
    var pressedModifiers: Set<Int64> = []
    var pendingKeyCode: Int64?
    var interrupted: Bool = false

    init(eisuKeyCode: Int64, kanaKeyCode: Int64) {
        self.eisuKeyCode = eisuKeyCode
        self.kanaKeyCode = kanaKeyCode
    }

    var triggerKeyCodes: Set<Int64> { [eisuKeyCode, kanaKeyCode] }

    func fireInputSwitch(for keyCode: Int64) {
        let targetVirtualKey: CGKeyCode = keyCode == eisuKeyCode
            ? EiKanaManager.KeyCode.eisuVirtualKey
            : EiKanaManager.KeyCode.kanaVirtualKey
        guard let source = CGEventSource(stateID: .hidSystemState),
              let keyDown = CGEvent(keyboardEventSource: source, virtualKey: targetVirtualKey, keyDown: true),
              let keyUp = CGEvent(keyboardEventSource: source, virtualKey: targetVirtualKey, keyDown: false) else { return }
        keyDown.post(tap: .cghidEventTap)
        keyUp.post(tap: .cghidEventTap)
    }
}

private func eiKanaEventTapCallback(
    proxy: CGEventTapProxy,
    type: CGEventType,
    event: CGEvent,
    refcon: UnsafeMutableRawPointer?
) -> Unmanaged<CGEvent>? {
    guard let refcon else { return Unmanaged.passUnretained(event) }
    let state = Unmanaged<EiKanaTapState>.fromOpaque(refcon).takeUnretainedValue()

    switch type {
    case .tapDisabledByTimeout, .tapDisabledByUserInput:
        // システムに無効化された場合は自前で即再有効化する(コールバックは軽量なのでタイムアウトは通常発生しない)
        if let tap = state.eventTap {
            CGEvent.tapEnable(tap: tap, enable: true)
        }

    case .flagsChanged:
        let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
        let isDown = !state.pressedModifiers.contains(keyCode)
        if isDown {
            state.pressedModifiers.insert(keyCode)
        } else {
            state.pressedModifiers.remove(keyCode)
        }

        if state.triggerKeyCodes.contains(keyCode) {
            if isDown {
                state.pendingKeyCode = keyCode
                state.interrupted = false
            } else if state.pendingKeyCode == keyCode {
                if !state.interrupted {
                    state.fireInputSwitch(for: keyCode)
                }
                state.pendingKeyCode = nil
            }
        } else if isDown, state.pendingKeyCode != nil {
            // トリガー以外の修飾キーが押されたら単押し判定を中断
            state.interrupted = true
        }

    case .keyDown, .leftMouseDown, .rightMouseDown, .otherMouseDown:
        if state.pendingKeyCode != nil {
            state.interrupted = true
        }

    default:
        break
    }

    return Unmanaged.passUnretained(event)
}

@MainActor
final class EiKanaManager: ObservableObject {
    static let shared = EiKanaManager()

    /// 割り当て可能な修飾キーの keycode。将来の拡張(左右⇧含む)のため全部定義しておく。
    enum KeyCode {
        static let leftCommand = 55
        static let rightCommand = 54
        static let leftOption = 58
        static let rightOption = 61
        static let leftControl = 59
        static let rightControl = 62
        static let leftShift = 56
        static let rightShift = 60

        static let eisuVirtualKey: CGKeyCode = 102 // kVK_JIS_Eisu
        static let kanaVirtualKey: CGKeyCode = 104 // kVK_JIS_Kana
    }

    struct AssignableKey {
        let keyCode: Int
        let label: String
    }

    static let assignableKeys: [AssignableKey] = [
        AssignableKey(keyCode: KeyCode.leftCommand, label: "左⌘"),
        AssignableKey(keyCode: KeyCode.rightCommand, label: "右⌘"),
        AssignableKey(keyCode: KeyCode.leftOption, label: "左⌥"),
        AssignableKey(keyCode: KeyCode.rightOption, label: "右⌥"),
        AssignableKey(keyCode: KeyCode.leftControl, label: "左⌃"),
        AssignableKey(keyCode: KeyCode.rightControl, label: "右⌃"),
    ]

    private enum DefaultsKey {
        static let enabled = "eiKanaEnabled"
        static let eisuKeyCode = "eiKanaEisuKeyCode"
        static let kanaKeyCode = "eiKanaKanaKeyCode"
    }

    @Published var enabled: Bool {
        didSet {
            guard oldValue != enabled else { return }
            UserDefaults.standard.set(enabled, forKey: DefaultsKey.enabled)
            restart()
        }
    }
    @Published var eisuKeyCode: Int {
        didSet {
            guard oldValue != eisuKeyCode else { return }
            UserDefaults.standard.set(eisuKeyCode, forKey: DefaultsKey.eisuKeyCode)
            restart()
        }
    }
    @Published var kanaKeyCode: Int {
        didSet {
            guard oldValue != kanaKeyCode else { return }
            UserDefaults.standard.set(kanaKeyCode, forKey: DefaultsKey.kanaKeyCode)
            restart()
        }
    }

    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var tapState: AnyObject?

    private init() {
        let defaults = UserDefaults.standard
        self.enabled = defaults.object(forKey: DefaultsKey.enabled) as? Bool ?? true
        self.eisuKeyCode = defaults.object(forKey: DefaultsKey.eisuKeyCode) as? Int ?? KeyCode.leftCommand
        self.kanaKeyCode = defaults.object(forKey: DefaultsKey.kanaKeyCode) as? Int ?? KeyCode.rightCommand
    }

    /// 冪等。無効設定 or Accessibility 未許可なら何もしない(既存 tap があれば作り直す前に破棄する)。
    func start() {
        stop()
        guard enabled else { return }
        guard AXIsProcessTrusted() else { return }

        let state = EiKanaTapState(eisuKeyCode: Int64(eisuKeyCode), kanaKeyCode: Int64(kanaKeyCode))
        let refcon = Unmanaged.passUnretained(state).toOpaque()

        let mask: CGEventMask = (1 << CGEventType.flagsChanged.rawValue)
            | (1 << CGEventType.keyDown.rawValue)
            | (1 << CGEventType.leftMouseDown.rawValue)
            | (1 << CGEventType.rightMouseDown.rawValue)
            | (1 << CGEventType.otherMouseDown.rawValue)

        guard let tap = CGEvent.tapCreate(
            tap: .cghidEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: mask,
            callback: eiKanaEventTapCallback,
            userInfo: refcon
        ) else {
            // 権限が取れていない等で生成失敗。次回 start() 呼び出しで再試行する。
            return
        }
        state.eventTap = tap

        let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        CFRunLoopAddSource(CFRunLoopGetCurrent(), source, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)

        tapState = state
        eventTap = tap
        runLoopSource = source
    }

    func stop() {
        if let tap = eventTap {
            CGEvent.tapEnable(tap: tap, enable: false)
        }
        if let source = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetCurrent(), source, .commonModes)
        }
        eventTap = nil
        runLoopSource = nil
        tapState = nil
    }

    func restart() {
        stop()
        start()
    }
}
