// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "OrdnerMeisterData",
    platforms: [.macOS(.v14)],
    products: [
        .library(
            name: "OrdnerMeisterData",
            targets: ["OrdnerMeisterData"]
        ),
    ],
    dependencies: [
        .package(path: "../OrdnerMeisterDomain"),
        .package(url: "https://github.com/fcanas/Bayes", from: "1.0.0")
    ],
    targets: [
        .target(
            name: "OrdnerMeisterData",
            dependencies: [
                "OrdnerMeisterDomain",
                .product(name: "Bayes", package: "Bayes")
            ]
        ),
        .testTarget(
            name: "OrdnerMeisterDataTests",
            dependencies: ["OrdnerMeisterData"]
        ),
    ]
)
