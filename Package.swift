// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "JSONToolbox",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(
            name: "JSONToolbox",
            path: "Sources/JSONToolbox"
        )
    ]
)
