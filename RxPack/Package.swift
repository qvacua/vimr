// swift-tools-version:5.6

import PackageDescription

let package = Package(
  name: "RxPack",
  platforms: [.macOS(.v10_13)],
  products: [
    .library(name: "RxPack", targets: ["RxPack"]),
  ],
  dependencies: [
    .package(url: "https://github.com/ReactiveX/RxSwift", .upToNextMinor(from: "6.5.0")),
    .package(url: "https://github.com/a2/MessagePack.swift", from: "4.0.0"),
    .package(url: "https://github.com/IBM-Swift/BlueSocket", from: "2.0.2"),
  ],
  targets: [
    .target(name: "RxPack", dependencies: [
      "RxSwift",
      .product(name: "MessagePack", package: "MessagePack.swift"),
      .product(name: "Socket", package: "BlueSocket"),
    ]),
    .testTarget(name: "RxPackTests", dependencies: ["RxPack"]),
  ]
)
