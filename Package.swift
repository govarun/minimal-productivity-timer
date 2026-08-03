// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Bell",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "Bell", targets: ["Bell"])
    ],
    targets: [
        .executableTarget(name: "Bell")
    ]
)
