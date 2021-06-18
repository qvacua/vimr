// swift-tools-version:5.3

import PackageDescription

let package = Package(
  name: "Workspace",
  platforms: [.macOS(.v10_13)],
  products: [
    .library(name: "Workspace", targets: ["Workspace"]),
  ],
  dependencies: [
    .package(
      name: "PureLayout",
      url: "https://github.com/PureLayout/PureLayout",
      .upToNextMinor(from: "3.1.9")
    ),
    .package(
      name: "MaterialIcons",
      url: "https://github.com/qvacua/material-icons",
      .upToNextMinor(from: "0.1.0")
    ),
    .package(path: "../Commons"),
  ],
  targets: [
    .target(
      name: "Workspace",
      dependencies: ["PureLayout", "MaterialIcons", "Commons"]
    ),
    .testTarget(
      name: "WorkspaceTests",
      dependencies: ["Workspace"]
    ),
  ]
)
