// swift-tools-version: 6.1
import PackageDescription

let package = Package(
    name: "ScreenCaptureApp",
    platforms: [.macOS(.v13)],
    products: [
        .executable(name: "ScreenCaptureApp", targets: ["App"])
    ],
    targets: [
        .executableTarget(
            name: "App",
            path: "Sources/App"
        )
    ]
)
