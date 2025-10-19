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
    .package(url: "https://github.com/Kitura/BlueSocket", .upToNextMinor(from: "2.0.2")),
    .package(url: "https://github.com/SimplyDanny/SwiftLintPlugins", from: "0.62.1"),
    .package(name: "Commons", path: "../Commons"),
  ],
  targets: [
    .target(
      name: "NvimApi",
      dependencies: [
        .product(name: "MessagePack", package: "MessagePack.swift"),
        .product(name: "Socket", package: "BlueSocket"),
        "Commons",
      ],
      plugins: [.plugin(name: "SwiftLintBuildToolPlugin", package: "SwiftLintPlugins")]
    ),
    .testTarget(
      name: "NvimApiTests",
      dependencies: [
        "NvimApi",
      ]
    ),
  ]
)
