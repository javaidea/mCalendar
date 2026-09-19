// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "mCalendar",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v13)
    ],
    targets: [
        .executableTarget(
            name: "mCalendar",
            path: "Sources/mCalendar",
            resources: [.process("Resources")]
        )
    ]
)
