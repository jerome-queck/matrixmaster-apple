// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "MatrixPersistence",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "MatrixPersistence",
            targets: ["MatrixPersistence"]
        )
    ],
    dependencies: [
        .package(path: "../MatrixDomain")
    ],
    targets: [
        .target(
            name: "MatrixPersistence",
            dependencies: ["MatrixDomain"]
        ),
        .testTarget(
            name: "MatrixPersistenceTests",
            dependencies: ["MatrixPersistence", "MatrixDomain"]
        )
    ]
)
