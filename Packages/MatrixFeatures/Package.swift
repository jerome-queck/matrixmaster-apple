// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "MatrixFeatures",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "MatrixFeatures",
            targets: ["MatrixFeatures"]
        )
    ],
    dependencies: [
        .package(path: "../MatrixDomain"),
        .package(path: "../MatrixUI"),
        .package(path: "../MatrixPersistence"),
        .package(path: "../MatrixExact"),
        .package(path: "../MatrixNumeric"),
        .package(path: "../MatrixAutomation")
    ],
    targets: [
        .target(
            name: "MatrixFeatures",
            dependencies: [
                "MatrixDomain",
                "MatrixUI",
                "MatrixPersistence",
                "MatrixExact",
                "MatrixNumeric",
                "MatrixAutomation"
            ]
        ),
        .testTarget(
            name: "MatrixFeaturesTests",
            dependencies: ["MatrixFeatures", "MatrixDomain"]
        )
    ]
)
