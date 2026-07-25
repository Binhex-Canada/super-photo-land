// swift-tools-version:6.2
import PackageDescription

let package = Package(
    name: "SuperPhotoLand",
    platforms: [
        .macOS(.v26)
    ],
    products: [
        .executable(name: "SuperPhotoLand", targets: ["PhotoEditorApp"]),
        .library(name: "PhotoEditorCore", type: .dynamic, targets: ["PhotoEditorCore"])
    ],
    dependencies: [],
    targets: [
        .target(
            name: "PhotoEditorCore",
            path: "Sources/PhotoEditorCore"
        ),
        .executableTarget(
            name: "PhotoEditorApp",
            dependencies: ["PhotoEditorCore"],
            path: "Sources/PhotoEditorApp"
        ),
        .testTarget(
            name: "PhotoEditorCoreTests",
            dependencies: ["PhotoEditorCore"],
            path: "Tests/PhotoEditorCoreTests"
        )
    ]
)
