// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "FlyquizCore",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "FlyquizCore", targets: ["FlyquizCore"]),
    ],
    targets: [
        .target(name: "FlyquizCore"),
        .testTarget(name: "FlyquizCoreTests", dependencies: ["FlyquizCore"]),
    ]
)
