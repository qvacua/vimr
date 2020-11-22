// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "Tabs",
  platforms: [.macOS(.v10_13)],
  products: [
    // Products define the executables and libraries a package produces, and make them visible to other packages.
    .library(
      name: "Tabs",
      targets: ["Tabs"]
    ),
  ],
  dependencies: [
    .package(name: "MaterialIcons", url: "https://github.com/qvacua/material-icons", .upToNextMinor(from: "0.1.0")),
    .package(
      name: "PureLayout",
      url: "https://github.com/PureLayout/PureLayout",
      .upToNextMinor(from: "3.1.6")
    ),
  ],
  targets: [
    // Targets are the basic building blocks of a package. A target can define a module or a test suite.
    // Targets can depend on other targets in this package, and on products in packages this package depends on.
    .target(
      name: "Tabs",
      dependencies: ["PureLayout", "MaterialIcons"]
    ),
    .testTarget(
      name: "TabsTests",
      dependencies: ["Tabs"]
    ),
  ]
)
