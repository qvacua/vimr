// swift-tools-version: 6.0

import PackageDescription

let package = Package(
  name: "NvimApi",
  platforms: [.macOS(.v14)],
  products: [
    .library(name: "NvimApi", targets: ["NvimApi"]),
  ],
  dependencies: [
    .package(url: "https://github.com/qvacua/MessagePack.swift", .upToNextMinor(from: "4.1.0")),
    .package(url: "https://github.com/qvacua/BlueSocket", from: "2.1.0"),
    .package(url: "https://github.com/SimplyDanny/SwiftLintPlugins", .upToNextMajor(from: "0.62.2")),
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
