// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "MinimalTimecard",
    platforms: [
        .macOS(.v15)
    ],
    targets: [
        .executableTarget(
            name: "MinimalTimecard",
            path: "Sources/MinimalTimecard",
            exclude: ["Resources/Info.plist"]
        ),
        .testTarget(
            name: "MinimalTimecardTests",
            dependencies: ["MinimalTimecard"],
            path: "Tests/MinimalTimecardTests"
        ),
    ]
)
