import SwiftUI
import ServiceManagement

struct SettingsView: View {
    @ObservedObject private var guard_ = AccessibilityGuard.shared
    @State private var launchAtLogin: Bool = false

    var body: some View {
        TabView {
            generalTab
                .tabItem { Label("一般", systemImage: "gear") }
            shortcutsTab
                .tabItem { Label("ショートカット", systemImage: "command") }
            aboutTab
                .tabItem { Label("このアプリ", systemImage: "info.circle") }
        }
        .frame(width: 420, height: 380)
        .onAppear {
            launchAtLogin = SMAppService.mainApp.status == .enabled
            guard_.refresh()
        }
    }

    private var generalTab: some View {
        Form {
            Section {
                Toggle("ログイン時に起動", isOn: $launchAtLogin)
                    .onChange(of: launchAtLogin) { _, newValue in
                        toggleLaunchAtLogin(newValue)
                    }
            }
            Section("アクセス権") {
                HStack {
                    Image(systemName: guard_.isTrusted ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                        .foregroundStyle(guard_.isTrusted ? .green : .orange)
                    Text(guard_.isTrusted ? "Accessibility を許可済み" : "Accessibility 未許可")
                    Spacer()
                    Button("設定を開く") { guard_.openSystemSettings() }
                }
            }
            Section {
                HStack {
                    Spacer()
                    Button(role: .destructive) {
                        NSApp.terminate(nil)
                    } label: {
                        Label("QuickSplit を終了", systemImage: "power")
                    }
                }
            }
        }
        .formStyle(.grouped)
    }

    private var shortcutsTab: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                ForEach(WindowAction.groups, id: \.title) { group in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(group.title)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(.secondary)
                            .textCase(.uppercase)
                        ForEach(group.actions) { action in
                            ShortcutRowView(action: action)
                        }
                    }
                }
            }
            .padding()
        }
    }

    private var aboutTab: some View {
        VStack(spacing: 12) {
            Image(systemName: "rectangle.split.2x2")
                .font(.system(size: 48))
                .foregroundStyle(.tint)
            Text("QuickSplit")
                .font(.title2.bold())
            Text("macOS ネイティブな画面分割ショートカットマネージャ")
                .font(.callout)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func toggleLaunchAtLogin(_ enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            launchAtLogin = SMAppService.mainApp.status == .enabled
        }
    }
}

#Preview("Settings") {
    SettingsView()
}
