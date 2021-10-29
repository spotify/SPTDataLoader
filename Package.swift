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
        .target(name: "SPTDataLoader", path: "Sources/SPTDataLoader"),
        .testTarget(
            name: "SPTDataLoaderTests",
            dependencies: ["SPTDataLoader"],
            path: "Tests/SPTDataLoader",
            exclude: ["Info.plist"],
            resources: [.process("Resources")],
            cSettings: [
                .headerSearchPath("../../Sources/SPTDataLoader"),
                .headerSearchPath("../../Tests/SPTDataLoader/Utilities"),
            ]
        ),

        .target(name: "SPTDataLoaderSwift", dependencies: ["SPTDataLoader"], path: "Sources/SPTDataLoaderSwift"),
        .testTarget(
            name: "SPTDataLoaderSwiftTests",
            dependencies: ["SPTDataLoaderSwift"],
            path: "Tests/SPTDataLoaderSwift",
            exclude: ["Info.plist"]
        ),
    ]
)
