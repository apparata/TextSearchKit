// swift-tools-version:6.2

import PackageDescription

let package = Package(
    name: "TextSearchKit",
    platforms: [
        .macOS(.v14),
    ],
    products: [
        .library(name: "TextSearchKit", targets: ["TextSearchKit"])
    ],
    targets: [
        .target(
            name: "TextSearchKit",
            dependencies: [],
            swiftSettings: [
                .define("DEBUG", .when(configuration: .debug)),
                .define("RELEASE", .when(configuration: .release)),
                .define("SWIFT_PACKAGE")
            ]),
        .executableTarget(
            name: "textsearch",
            dependencies: ["TextSearchKit"],
            swiftSettings: [
                .define("DEBUG", .when(configuration: .debug)),
                .define("RELEASE", .when(configuration: .release)),
                .define("SWIFT_PACKAGE")
            ]),
        .testTarget(name: "TextSearchKitTests", dependencies: ["TextSearchKit"]),
    ]
)
