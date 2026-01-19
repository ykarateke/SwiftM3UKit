// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "SwiftM3UKit",
    platforms: [
        .iOS(.v15),
        .tvOS(.v15),
        .macOS(.v12)
    ],
    products: [
        .library(name: "SwiftM3UKit", targets: ["SwiftM3UKit"])
    ],
    dependencies: [
        .package(url: "https://github.com/swiftlang/swift-docc-plugin", from: "1.4.4")
    ],
    targets: [
        .target(
            name: "SwiftM3UKit",
            swiftSettings: [
                .enableExperimentalFeature("StrictConcurrency")
            ]
        ),
        .testTarget(
            name: "SwiftM3UKitTests",
            dependencies: ["SwiftM3UKit"],
            resources: [
                .copy("Resources")
            ]
        ),
        .executableTarget(
            name: "PlaylistAnalyzer",
            dependencies: ["SwiftM3UKit"],
            path: "Tools/PlaylistAnalyzer"
        )
    ]
)
