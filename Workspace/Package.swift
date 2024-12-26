// swift-tools-version: 6.0

import PackageDescription

let package = Package(
  name: "Workspace",
  platforms: [.macOS(.v12)],
  products: [
    .library(name: "Workspace", targets: ["Workspace"]),
  ],
  dependencies: [
    .package(url: "https://github.com/PureLayout/PureLayout", from: "3.1.9"),
    .package(url: "https://github.com/qvacua/material-icons", from: "0.1.0"),
    .package(path: "../Commons"),
  ],
  targets: [
    .target(
      name: "Workspace",
      dependencies: [
        "PureLayout",
        .product(name: "MaterialIcons", package: "material-icons"),
        "Commons",
      ]
    ),
  ]
)
