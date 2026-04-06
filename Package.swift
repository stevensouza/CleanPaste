// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "CleanPaste",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(
            name: "CleanPaste",
            path: "Sources/CleanPaste",
            resources: [.copy("Info.plist")]
        )
    ]
)
