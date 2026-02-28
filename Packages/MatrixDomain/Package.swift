// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "MatrixDomain",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "MatrixDomain",
            targets: ["MatrixDomain"]
        )
    ],
    targets: [
        .target(
            name: "MatrixDomain"
        ),
        .testTarget(
            name: "MatrixDomainTests",
            dependencies: ["MatrixDomain"]
        )
    ]
)
