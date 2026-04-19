#if DEBUG
import AppKit
import SwiftUI

struct SnapshotPalette {
    let background: Color
    let primary: Color
    let secondary: Color
    let tertiary: Color
    let divider: Color
    let pillBackground: Color
    let pillBorder: Color
    let accent: Color

    static let light = SnapshotPalette(
        background: Color(red: 1.0, green: 1.0, blue: 1.0),
        primary: Color(red: 0.11, green: 0.11, blue: 0.12),
        secondary: Color(red: 0.35, green: 0.35, blue: 0.37),
        tertiary: Color(red: 0.55, green: 0.55, blue: 0.57),
        divider: Color(red: 0.87, green: 0.87, blue: 0.88),
        pillBackground: Color(red: 0.93, green: 0.93, blue: 0.94),
        pillBorder: Color(red: 0.82, green: 0.82, blue: 0.84),
        accent: Color(red: 0.0, green: 0.48, blue: 1.0)
    )

    static let dark = SnapshotPalette(
        background: Color(red: 0.12, green: 0.12, blue: 0.13),
        primary: Color(red: 0.96, green: 0.96, blue: 0.97),
        secondary: Color(red: 0.70, green: 0.70, blue: 0.72),
        tertiary: Color(red: 0.52, green: 0.52, blue: 0.54),
        divider: Color(red: 0.24, green: 0.24, blue: 0.26),
        pillBackground: Color(red: 0.24, green: 0.24, blue: 0.26),
        pillBorder: Color(red: 0.32, green: 0.32, blue: 0.34),
        accent: Color(red: 0.04, green: 0.52, blue: 1.0)
    )
}

@MainActor
enum ScreenshotRenderer {
    static func runIfRequested() -> Bool {
        guard CommandLine.arguments.contains("--render-screenshots") else { return false }

        let outDir: URL
        if let idx = CommandLine.arguments.firstIndex(of: "--out"),
           idx + 1 < CommandLine.arguments.count {
            outDir = URL(fileURLWithPath: CommandLine.arguments[idx + 1])
        } else {
            outDir = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
                .appendingPathComponent("docs/screenshots")
        }
        try? FileManager.default.createDirectory(at: outDir, withIntermediateDirectories: true)

        render(PopoverSnapshot(palette: .light).frame(width: 340), background: SnapshotPalette.light.background,
               to: outDir.appendingPathComponent("popover-light.png"))
        render(PopoverSnapshot(palette: .dark).frame(width: 340), background: SnapshotPalette.dark.background,
               to: outDir.appendingPathComponent("popover-dark.png"))

        FileHandle.standardOutput.write(Data("rendered to \(outDir.path)\n".utf8))
        return true
    }

    private static func render<V: View>(_ view: V, background: Color, to url: URL) {
        let wrapped = view.background(background)

        let renderer = ImageRenderer(content: wrapped)
        renderer.scale = 2.0
        renderer.isOpaque = true

        guard let nsImage = renderer.nsImage,
              let tiff = nsImage.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiff),
              let png = bitmap.representation(using: .png, properties: [:]) else {
            FileHandle.standardError.write(Data("failed to render \(url.lastPathComponent)\n".utf8))
            return
        }
        try? png.write(to: url)
    }
}

// Static snapshot of the popover designed for offscreen ImageRenderer capture.
// KeyboardShortcuts.Recorder is an NSView-backed control that doesn't render
// in ImageRenderer, so we swap it for a visual shortcut pill with sample keys.
private struct PopoverSnapshot: View {
    let palette: SnapshotPalette

    private static let sampleShortcuts: [WindowAction: String] = [
        .leftHalf: "⌃⌥←",
        .rightHalf: "⌃⌥→",
        .topHalf: "⌃⌥↑",
        .bottomHalf: "⌃⌥↓",
        .topLeft: "⌃⌥U",
        .topRight: "⌃⌥I",
        .bottomLeft: "⌃⌥J",
        .bottomRight: "⌃⌥K",
        .firstThird: "⌃⌥D",
        .centerThird: "⌃⌥F",
        .lastThird: "⌃⌥G",
        .center: "⌃⌥C",
        .maximize: "⌃⌥↩",
        .almostMaximize: "⌃⌥⇧↩",
        .restore: "⌃⌥⌫"
    ]

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Image(systemName: "rectangle.split.2x2")
                    .foregroundStyle(palette.accent)
                Text("QuickSplit")
                    .font(.headline)
                    .foregroundStyle(palette.primary)
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)

            palette.divider.frame(height: 0.5)

            VStack(alignment: .leading, spacing: 8) {
                ForEach(WindowAction.groups, id: \.title) { group in
                    VStack(alignment: .leading, spacing: 2) {
                        Text(group.title)
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(palette.tertiary)
                            .textCase(.uppercase)
                            .padding(.horizontal, 12)
                            .padding(.top, 4)
                        ForEach(group.actions) { action in
                            snapshotRow(for: action)
                        }
                    }
                }
            }
            .padding(.vertical, 8)

            palette.divider.frame(height: 0.5)

            HStack(spacing: 4) {
                Image(systemName: "gearshape")
                Text("設定...")
                Spacer()
                Image(systemName: "power")
                Text("終了")
            }
            .font(.system(size: 12))
            .foregroundStyle(palette.secondary)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
    }

    private func snapshotRow(for action: WindowAction) -> some View {
        HStack(spacing: 12) {
            Image(systemName: action.symbolName)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(palette.secondary)
                .frame(width: 22, alignment: .center)

            Text(action.displayName)
                .font(.system(size: 13))
                .foregroundStyle(palette.primary)

            Spacer(minLength: 8)

            shortcutPill(Self.sampleShortcuts[action] ?? "—")

            Image(systemName: "play.fill")
                .font(.system(size: 9))
                .foregroundStyle(palette.tertiary)
                .frame(width: 18, height: 18)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 4)
    }

    private func shortcutPill(_ keys: String) -> some View {
        Text(keys)
            .font(.system(size: 12, weight: .medium, design: .rounded))
            .foregroundStyle(palette.primary)
            .padding(.horizontal, 10)
            .padding(.vertical, 3)
            .background(
                RoundedRectangle(cornerRadius: 5, style: .continuous)
                    .fill(palette.pillBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 5, style: .continuous)
                    .strokeBorder(palette.pillBorder, lineWidth: 0.5)
            )
    }
}
#endif
