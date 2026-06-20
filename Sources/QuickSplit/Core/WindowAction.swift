import Foundation

enum WindowAction: String, CaseIterable, Identifiable, Sendable {
    case leftHalf, rightHalf, topHalf, bottomHalf
    case topLeft, topRight, bottomLeft, bottomRight
    case firstThird, centerThird, lastThird
    case center
    case maximize, almostMaximize
    case restore
    case firstFourth, secondFourth, thirdFourth, lastFourth

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .leftHalf: return "左半分"
        case .rightHalf: return "右半分"
        case .topHalf: return "上半分"
        case .bottomHalf: return "下半分"
        case .topLeft: return "左上 1/4"
        case .topRight: return "右上 1/4"
        case .bottomLeft: return "左下 1/4"
        case .bottomRight: return "右下 1/4"
        case .firstThird: return "左 1/3"
        case .centerThird: return "中央 1/3"
        case .lastThird: return "右 1/3"
        case .center: return "中央に寄せる"
        case .maximize: return "最大化"
        case .almostMaximize: return "ほぼ最大化 (90%)"
        case .restore: return "元に戻す"
        case .firstFourth: return "左 1/4"
        case .secondFourth: return "中左 1/4"
        case .thirdFourth: return "中右 1/4"
        case .lastFourth: return "右 1/4"
        }
    }

    var symbolName: String {
        switch self {
        case .leftHalf: return "rectangle.lefthalf.filled"
        case .rightHalf: return "rectangle.righthalf.filled"
        case .topHalf: return "rectangle.tophalf.filled"
        case .bottomHalf: return "rectangle.bottomhalf.filled"
        case .topLeft: return "rectangle.inset.topleft.filled"
        case .topRight: return "rectangle.inset.topright.filled"
        case .bottomLeft: return "rectangle.inset.bottomleft.filled"
        case .bottomRight: return "rectangle.inset.bottomright.filled"
        case .firstThird, .centerThird, .lastThird: return "rectangle.split.3x1"
        case .firstFourth, .secondFourth, .thirdFourth, .lastFourth: return "rectangle.split.4x1"
        case .center: return "rectangle.center.inset.filled"
        case .maximize: return "rectangle.inset.filled"
        case .almostMaximize: return "rectangle.dashed"
        case .restore: return "arrow.uturn.backward"
        }
    }

    static let groups: [(title: String, actions: [WindowAction])] = [
        ("ハーフ", [.leftHalf, .rightHalf, .topHalf, .bottomHalf]),
        ("クォーター", [.topLeft, .topRight, .bottomLeft, .bottomRight]),
        ("サード", [.firstThird, .centerThird, .lastThird]),
        ("フォース", [.firstFourth, .secondFourth, .thirdFourth, .lastFourth]),
        ("その他", [.center, .maximize, .almostMaximize, .restore])
    ]
}
