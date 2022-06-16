// swift-tools-version:5.6

import PackageDescription

let package = Package(
  name: "Workspace",
  platforms: [.macOS(.v10_13)],
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
    .testTarget(
      name: "WorkspaceTests",
      dependencies: ["Workspace"]
    ),
  ]
)
