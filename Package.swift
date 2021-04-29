// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(name: "PanelUI",
                      platforms: [
                          .iOS(.v14)
                      ],
                      products: [
                          .library(name: "PanelUI",
                                   targets: ["PanelUI"])
                      ],
                      dependencies: [
                          .package(url: "https://github.com/IdeasOnCanvas/Aiolos.git", from: "1.4.0")
                      ],
                      targets: [
                          .target(name: "PanelUI",
                                  dependencies: [
                                      "Aiolos"
                                  ]),
                          .testTarget(name: "PanelUITests",
                                      dependencies: ["PanelUI"])
                      ])
