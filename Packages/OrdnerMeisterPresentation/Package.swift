// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "OrdnerMeisterPresentation",
    platforms: [.macOS(.v14)],
    products: [
        .library(
            name: "OrdnerMeisterPresentation",
            targets: ["OrdnerMeisterPresentation"]
        ),
    ],
    dependencies: [
        .package(path: "../OrdnerMeisterDomain")
    ],
    targets: [
        .target(
            name: "OrdnerMeisterPresentation",
            dependencies: ["OrdnerMeisterDomain"]
        ),
        .testTarget(
            name: "OrdnerMeisterPresentationTests",
            dependencies: ["OrdnerMeisterPresentation"]
        ),
    ]
)
