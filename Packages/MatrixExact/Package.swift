// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "MatrixExact",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "MatrixExact",
            targets: ["MatrixExact"]
        )
    ],
    dependencies: [
        .package(path: "../MatrixDomain")
    ],
    targets: [
        .target(
            name: "MatrixExact",
            dependencies: ["MatrixDomain"]
        ),
        .testTarget(
            name: "MatrixExactTests",
            dependencies: ["MatrixExact", "MatrixDomain"]
        )
    ]
)
