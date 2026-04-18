import SwiftUI
import KeyboardShortcuts

struct ShortcutRowView: View {
    let action: WindowAction

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: action.symbolName)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.secondary)
                .frame(width: 22, alignment: .center)

            Text(action.displayName)
                .font(.system(size: 13))

            Spacer(minLength: 8)

            KeyboardShortcuts.Recorder(for: action.shortcutName)

            Button {
                WindowManager.shared.perform(action)
            } label: {
                Image(systemName: "play.fill")
                    .font(.system(size: 10))
            }
            .buttonStyle(.borderless)
            .help("今すぐ実行")
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 4)
    }
}

#Preview("ShortcutRow") {
    VStack(spacing: 0) {
        ShortcutRowView(action: .leftHalf)
        ShortcutRowView(action: .maximize)
        ShortcutRowView(action: .restore)
    }
    .frame(width: 340)
    .padding(.vertical, 8)
}
