// swift-tools-version:5.2

import PackageDescription

let package = Package(
    name: "MoyaIntegrationTesting",
    platforms: [
        .macOS(.v10_12),
        .iOS(.v10),
        .tvOS(.v10),
        .watchOS(.v3)
    ],
    products: [
        .library(name: "MoyaIntegrationTesting", targets: ["MoyaIntegrationTesting"])
    ],
    dependencies: [
        .package(url: "https://github.com/Moya/Moya.git", .upToNextMajor(from: "14.0.0"))
    ],
    targets: [
        .target(name: "MoyaIntegrationTesting", dependencies: ["Moya"]),
        .testTarget(name: "MoyaIntegrationTestingTests", dependencies: ["MoyaIntegrationTesting", "Moya"])
    ]
)
