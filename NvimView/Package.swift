// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "NvimView",
  platforms: [.macOS(.v10_13)],
  products: [
    // Products define the executables and libraries a package produces, and make them visible to other packages.
    .library(
      name: "NvimView",
      targets: ["NvimView"]),
  ],
  dependencies: [
    // Dependencies declare other packages that this package depends on.
    .package(name: "MessagePack", url: "https://github.com/a2/MessagePack.swift", .exact("4.0.0")),
    .package(url: "https://github.com/ReactiveX/RxSwift", .exact("5.1.1")),
    .package(name: "Socket", url: "https://github.com/IBM-Swift/BlueSocket", .exact("1.0.52")),
  ],
  targets: [
    // Targets are the basic building blocks of a package. A target can define a module or a test suite.
    // Targets can depend on other targets in this package, and on products in packages this package depends on.
    .target(
      name: "NvimView",
      dependencies: ["RxSwift", "MessagePack", "Socket"],
      resources: [.copy("Resources")]),
    .testTarget(
      name: "NvimViewTests",
      dependencies: ["NvimView"]),
  ]
)
