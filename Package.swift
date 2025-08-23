// swift-tools-version:5.7
import PackageDescription

let package = Package(
    name: "CrownLoopTestsPackage",
    platforms: [.macOS(.v13)],
    products: [],
    targets: [
        .target(name: "CrownLoop", path: "Sources/CrownLoop"),
        .testTarget(name: "CrownLoopTests", dependencies: ["CrownLoop"], path: "Tests/CrownLoopTests")
    ]
)
