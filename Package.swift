// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "MotionTimer",
    platforms: [
        .macOS(.v14)
    ],
    targets: [
        .executableTarget(
            name: "MotionTimer",
            path: "MotionTimer",
            resources: [
                .process("Resources")
            ]
        )
    ]
)
