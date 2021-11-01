// swift-tools-version:5.3
import PackageDescription

let package = Package(
    name: "SPTDataLoader",
    platforms: [
        .iOS(.v10),
        .macOS(.v10_12),
        .tvOS(.v10),
        .watchOS(.v3),
    ],
    products: [
        .library(name: "SPTDataLoader", targets: ["SPTDataLoaderSwift"]),
    ],
    targets: [
        .target(
            name: "SPTDataLoader",
            path: "SPTDataLoader",
            exclude: ["Info.plist", "Tests"]
        ),
        .testTarget(
            name: "SPTDataLoaderTests",
            dependencies: ["SPTDataLoader"],
            path: "SPTDataLoader/Tests",
            exclude: ["Info.plist"],
            resources: [.process("Resources")],
            cSettings: [
                .headerSearchPath("Utilities"),
                .headerSearchPath("../Sources"),
            ]
        ),

        .target(
            name: "SPTDataLoaderSwift",
            dependencies: ["SPTDataLoader"],
            path: "SPTDataLoaderSwift",
            exclude: ["Tests"]
        ),
        .testTarget(
            name: "SPTDataLoaderSwiftTests",
            dependencies: ["SPTDataLoaderSwift"],
            path: "SPTDataLoaderSwift/Tests",
            exclude: ["Info.plist"]
        ),
    ]
)
