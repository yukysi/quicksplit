import SwiftUI

struct MenuBarPopoverView: View {
    @ObservedObject private var guard_ = AccessibilityGuard.shared
    @Environment(\.openSettings) private var openSettings

    var body: some View {
        VStack(spacing: 0) {
            header

            if !guard_.isTrusted {
                permissionBanner
            }

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(WindowAction.groups, id: \.title) { group in
                        groupSection(title: group.title, actions: group.actions)
                    }
                }
                .padding(.vertical, 8)
            }
            .frame(maxHeight: 420)

            Divider()
            footer
        }
        .frame(width: 340)
        .onAppear { guard_.refresh() }
    }

    private var header: some View {
        HStack {
            Image(systemName: "rectangle.split.2x2")
                .foregroundStyle(.tint)
            Text("QuickSplit")
                .font(.headline)
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }

    private var permissionBanner: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label("Accessibility の許可が必要です", systemImage: "exclamationmark.triangle.fill")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.orange)
            Text("ウィンドウを操作するためシステム設定で QuickSplit を許可してください。")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
            HStack {
                Button("システム設定を開く") {
                    guard_.openSystemSettings()
                }
                .controlSize(.small)
                Button("再確認") {
                    guard_.refresh()
                }
                .controlSize(.small)
            }
        }
        .padding(10)
        .background(Color.orange.opacity(0.1))
    }

    private func groupSection(title: String, actions: [WindowAction]) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
                .padding(.horizontal, 12)
                .padding(.top, 4)
            ForEach(actions) { action in
                ShortcutRowView(action: action)
            }
        }
    }

    private var footer: some View {
        HStack {
            Button {
                NSApp.activate(ignoringOtherApps: true)
                openSettings()
            } label: {
                Label("設定...", systemImage: "gearshape")
            }
            .buttonStyle(.borderless)

            Spacer()

            Button {
                NSApp.terminate(nil)
            } label: {
                Label("終了", systemImage: "power")
            }
            .buttonStyle(.borderless)
        }
        .font(.system(size: 12))
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }
}

#Preview("Popover") {
    MenuBarPopoverView()
}
