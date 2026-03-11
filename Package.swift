// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "Motley",
    platforms: [
        .iOS(.v16),
        .watchOS(.v9),
        .tvOS(.v18),
        .macOS(.v13),
    ],
    products: [
        .library(name: "MotleyCore", targets: ["MotleyCore"]),
        .library(name: "MotleyUI", targets: ["MotleyUI"]),
    ],
    dependencies: [
        .package(url: "https://github.com/SimplyDanny/SwiftLintPlugins", from: "0.63.0"),
    ],
    targets: [
        .target(
            name: "MotleyCore",
            path: "Sources/MotleyCore",
            swiftSettings: [
                .enableUpcomingFeature("NonisolatedNonsendingByDefault"),
                .enableUpcomingFeature("InferIsolatedConformances"),
                .enableUpcomingFeature("ExistentialAny"),
            ],
            plugins: [
                .plugin(name: "SwiftLintBuildToolPlugin", package: "SwiftLintPlugins"),
            ],
        ),
        .testTarget(
            name: "MotleyCoreTests",
            dependencies: ["MotleyCore"],
            path: "Tests/MotleyCoreTests",
        ),
        .target(
            name: "MotleyUI",
            dependencies: ["MotleyCore"],
            path: "Sources/MotleyUI",
            swiftSettings: [
                .enableUpcomingFeature("NonisolatedNonsendingByDefault"),
                .enableUpcomingFeature("InferIsolatedConformances"),
                .enableUpcomingFeature("ExistentialAny"),
            ],
            plugins: [
                .plugin(name: "SwiftLintBuildToolPlugin", package: "SwiftLintPlugins"),
            ],
        ),
        .testTarget(
            name: "MotleyUITests",
            dependencies: ["MotleyUI"],
            path: "Tests/MotleyUITests",
        ),
    ],
)
