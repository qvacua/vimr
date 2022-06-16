// swift-tools-version:5.6

import PackageDescription

let package = Package(
  name: "Tabs",
  platforms: [.macOS(.v10_13)],
  products: [
    .library(name: "Tabs", targets: ["Tabs"]),
  ],
  dependencies: [
    .package(url: "https://github.com/qvacua/material-icons", from: "0.1.0"),
    .package(url: "https://github.com/PureLayout/PureLayout", from: "3.1.9"),
  ],
  targets: [
    .target(
      name: "Tabs",
      dependencies: [
        "PureLayout",
        .product(name: "MaterialIcons", package: "material-icons"),
      ]
    ),
    .testTarget(name: "TabsTests", dependencies: ["Tabs"]),
  ]
)
