// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "MatrixUI",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "MatrixUI",
            targets: ["MatrixUI"]
        )
    ],
    dependencies: [
        .package(path: "../MatrixDomain")
    ],
    targets: [
        .target(
            name: "MatrixUI",
            dependencies: ["MatrixDomain"]
        ),
        .testTarget(
            name: "MatrixUITests",
            dependencies: ["MatrixUI", "MatrixDomain"]
        )
    ]
)
