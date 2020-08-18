// swift-tools-version:5.3

import PackageDescription

let package = Package(
  name: "Commons",
  platforms: [.macOS(.v10_13)],
  products: [
    .library(
      name: "Commons",
      targets: ["Commons"]),
  ],
  dependencies: [],
  targets: [
    .target(
      name: "Commons",
      dependencies: []
    ),
    .testTarget(
      name: "CommonsTests",
      dependencies: ["Commons"]
    ),
  ]
)
