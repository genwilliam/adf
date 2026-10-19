// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "AFG",
    platforms: [.macOS(.v15)],
    targets: [
        .executableTarget(name: "AFG", path: "Sources/AFG"),
        .executableTarget(name: "AFGIconHost", path: "Sources/AFGIconHost")
    ],
    swiftLanguageModes: [.v5]
)
