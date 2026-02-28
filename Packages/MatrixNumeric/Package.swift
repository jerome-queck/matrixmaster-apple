// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "MatrixNumeric",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "MatrixNumeric",
            targets: ["MatrixNumeric"]
        )
    ],
    dependencies: [
        .package(path: "../MatrixDomain")
    ],
    targets: [
        .target(
            name: "MatrixNumeric",
            dependencies: ["MatrixDomain"]
        ),
        .testTarget(
            name: "MatrixNumericTests",
            dependencies: ["MatrixNumeric", "MatrixDomain"]
        )
    ]
)
