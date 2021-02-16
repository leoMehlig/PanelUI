// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "PanelUI",
    platforms: [
        .iOS(.v14)
    ],
    products: [
        .library(
            name: "PanelUI",
            targets: ["PanelUI"]),
    ],
    targets: [
        .target(
            name: "PanelUI",
            dependencies: []),
        .testTarget(
            name: "PanelUITests",
            dependencies: ["PanelUI"]),
    ]
)
