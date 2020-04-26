// swift-tools-version:5.2

import PackageDescription

let package = Package(
    name: "TextSearchKit",
    platforms: [
        // Relevant platforms.
        .macOS(.v10_15),
    ],
    products: [
        .library(name: "TextSearchKit", targets: ["TextSearchKit"])
    ],
    dependencies: [
        // It's a good thing to keep things relatively
        // independent, but add any dependencies here.
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
        .target(
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
