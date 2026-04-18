import CoreGraphics

enum WindowLayoutCalculator {
    static func targetFrame(for action: WindowAction, in screen: CGRect) -> CGRect? {
        let x = screen.origin.x
        let y = screen.origin.y
        let w = screen.size.width
        let h = screen.size.height

        switch action {
        case .leftHalf:
            return CGRect(x: x, y: y, width: w / 2, height: h)
        case .rightHalf:
            return CGRect(x: x + w / 2, y: y, width: w / 2, height: h)
        case .topHalf:
            return CGRect(x: x, y: y, width: w, height: h / 2)
        case .bottomHalf:
            return CGRect(x: x, y: y + h / 2, width: w, height: h / 2)
        case .topLeft:
            return CGRect(x: x, y: y, width: w / 2, height: h / 2)
        case .topRight:
            return CGRect(x: x + w / 2, y: y, width: w / 2, height: h / 2)
        case .bottomLeft:
            return CGRect(x: x, y: y + h / 2, width: w / 2, height: h / 2)
        case .bottomRight:
            return CGRect(x: x + w / 2, y: y + h / 2, width: w / 2, height: h / 2)
        case .firstThird:
            return CGRect(x: x, y: y, width: w / 3, height: h)
        case .centerThird:
            return CGRect(x: x + w / 3, y: y, width: w / 3, height: h)
        case .lastThird:
            return CGRect(x: x + w * 2 / 3, y: y, width: w / 3, height: h)
        case .maximize:
            return CGRect(x: x, y: y, width: w, height: h)
        case .almostMaximize:
            let margin: CGFloat = 0.05
            return CGRect(
                x: x + w * margin,
                y: y + h * margin,
                width: w * (1 - margin * 2),
                height: h * (1 - margin * 2)
            )
        case .center, .restore:
            return nil
        }
    }

    static func centered(size: CGSize, in screen: CGRect) -> CGRect {
        let x = screen.origin.x + (screen.width - size.width) / 2
        let y = screen.origin.y + (screen.height - size.height) / 2
        return CGRect(origin: CGPoint(x: x, y: y), size: size)
    }
}
