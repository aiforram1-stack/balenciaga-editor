// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "BalenciagaEditor",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "BalenciagaEditor", targets: ["BalenciagaEditor"])
    ],
    targets: [
        .executableTarget(
            name: "BalenciagaEditor",
            path: "Sources/BalenciagaEditor"
        )
    ]
)
