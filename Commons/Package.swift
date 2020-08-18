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
  dependencies: [
    .package(url: "https://github.com/Quick/Nimble", .upToNextMinor(from: "8.1.1")),
  ],
  targets: [
    .target(
      name: "Commons",
      dependencies: []
    ),
    .testTarget(
      name: "CommonsTests",
      dependencies: ["Commons", "Nimble"]
    ),
  ]
)
