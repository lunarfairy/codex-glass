// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "CodexGlass",
    platforms: [.macOS(.v13)],
    products: [.executable(name: "CodexGlass", targets: ["CodexGlass"])],
    targets: [
        .target(name: "GlassCore"),
        .executableTarget(name: "CodexGlass", dependencies: ["GlassCore"]),
        .testTarget(name: "GlassCoreTests", dependencies: ["GlassCore"])
    ]
)
