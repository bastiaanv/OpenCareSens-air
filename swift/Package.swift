// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "OpenCareSensAir",
    products: [
        .library(
            name: "OpenCareSensAir",
            targets: ["OpenCareSensAir"]
        ),
    ],
    targets: [
        .target(
            name: "OpenCareSensAir",
            path: "Sources/OpenCareSensAir"
        ),
        .testTarget(
            name: "OpenCareSensAirTests",
            dependencies: ["OpenCareSensAir"],
            path: "Tests/OpenCareSensAirTests"
        ),
    ]
)
