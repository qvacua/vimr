// swift-tools-version: 6.0

import PackageDescription

let package = Package(
  name: "NvimApi",
  platforms: [.macOS(.v13)],
  products: [
    .library(name: "NvimApi", targets: ["NvimApi"]),
  ],
  dependencies: [
    .package(url: "https://github.com/qvacua/MessagePack.swift", .upToNextMinor(from: "4.1.0")),
  ],
  targets: [
    .target(name: "NvimApi", dependencies: [
      .product(name: "MessagePack", package: "MessagePack.swift"),
    ]),
    .testTarget(
      name: "NvimApiTests",
      dependencies: [
        "NvimApi",
      ]
    ),
  ]
)
