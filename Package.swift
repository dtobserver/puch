// swift-tools-version: 6.1
import PackageDescription

let package = Package(
    name: "Puch",
    platforms: [.macOS(.v13)],
    products: [
        .executable(name: "Puch", targets: ["App"])
    ],
    targets: [
        .executableTarget(
            name: "App",
            path: "Sources/App"
        ),
        .testTarget(
            name: "AppTests",
            dependencies: ["App"],
            path: "Tests/AppTests"
        )
    ]
)
