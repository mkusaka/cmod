// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "CmodSparkle",
    platforms: [
        .macOS(.v15),
    ],
    products: [
        .library(
            name: "CmodSparkle",
            targets: ["CmodSparkle"]
        ),
    ],
    dependencies: [
        .package(
            url: "https://github.com/sparkle-project/Sparkle",
            from: "2.9.1"
        ),
    ],
    targets: [
        .target(
            name: "CmodSparkle",
            dependencies: [
                .product(name: "Sparkle", package: "Sparkle"),
            ]
        ),
    ]
)
