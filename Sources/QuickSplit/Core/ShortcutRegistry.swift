import KeyboardShortcuts

extension KeyboardShortcuts.Name {
    static let leftHalf = Self("leftHalf")
    static let rightHalf = Self("rightHalf")
    static let topHalf = Self("topHalf")
    static let bottomHalf = Self("bottomHalf")
    static let topLeft = Self("topLeft")
    static let topRight = Self("topRight")
    static let bottomLeft = Self("bottomLeft")
    static let bottomRight = Self("bottomRight")
    static let firstThird = Self("firstThird")
    static let centerThird = Self("centerThird")
    static let lastThird = Self("lastThird")
    static let center = Self("center")
    static let maximize = Self("maximize")
    static let almostMaximize = Self("almostMaximize")
    static let restore = Self("restore")
}

extension WindowAction {
    var shortcutName: KeyboardShortcuts.Name {
        switch self {
        case .leftHalf: return .leftHalf
        case .rightHalf: return .rightHalf
        case .topHalf: return .topHalf
        case .bottomHalf: return .bottomHalf
        case .topLeft: return .topLeft
        case .topRight: return .topRight
        case .bottomLeft: return .bottomLeft
        case .bottomRight: return .bottomRight
        case .firstThird: return .firstThird
        case .centerThird: return .centerThird
        case .lastThird: return .lastThird
        case .center: return .center
        case .maximize: return .maximize
        case .almostMaximize: return .almostMaximize
        case .restore: return .restore
        }
    }
}

@MainActor
enum ShortcutRegistry {
    static func registerAll() {
        for action in WindowAction.allCases {
            KeyboardShortcuts.onKeyUp(for: action.shortcutName) {
                WindowManager.shared.perform(action)
            }
        }
    }
}
