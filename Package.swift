// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "QuickSplit",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "QuickSplit", targets: ["QuickSplit"])
    ],
    dependencies: [
        .package(url: "https://github.com/sindresorhus/KeyboardShortcuts", from: "2.2.0")
    ],
    targets: [
        .executableTarget(
            name: "QuickSplit",
            dependencies: [
                .product(name: "KeyboardShortcuts", package: "KeyboardShortcuts")
            ],
            path: "Sources/QuickSplit"
        )
    ]
)
