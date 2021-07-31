// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(name: "PanelUI",
                      platforms: [
                          .macOS(.v11), .iOS(.v14)
                      ],
                      products: [
                          .library(name: "PanelUI",
                                   targets: ["PanelUI"])
                      ],
                      dependencies: [
                          .package(path: "Aiolos")
                      ],
                      targets: [
                          .target(name: "PanelUI",
                                  dependencies: [
                                      .product(name: "Aiolos", package: "Aiolos", condition: .when(platforms: [.iOS]))
                                  ])
                      ])
