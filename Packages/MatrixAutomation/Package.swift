// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "MatrixAutomation",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "MatrixAutomation",
            targets: ["MatrixAutomation"]
        )
    ],
    dependencies: [
        .package(path: "../MatrixDomain")
    ],
    targets: [
        .target(
            name: "MatrixAutomation",
            dependencies: ["MatrixDomain"]
        ),
        .testTarget(
            name: "MatrixAutomationTests",
            dependencies: ["MatrixAutomation", "MatrixDomain"]
        )
    ]
)
