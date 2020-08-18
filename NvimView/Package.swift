// swift-tools-version:5.3

import PackageDescription

let package = Package(
  name: "NvimView",
  platforms: [.macOS(.v10_13)],
  products: [
    .library(name: "NvimView", targets: ["NvimView"]),
  ],
  dependencies: [
    .package(name: "MessagePack", url: "https://github.com/a2/MessagePack.swift", .upToNextMinor(from: "4.0.0")),
    .package(url: "https://github.com/ReactiveX/RxSwift", .upToNextMinor(from: "5.1.1")),
    .package(name: "Socket", url: "https://github.com/IBM-Swift/BlueSocket", .upToNextMinor(from: "1.0.52")),
  ],
  targets: [
    .target(
      name: "NvimView",
      dependencies: ["RxSwift", "MessagePack", "Socket"],
      resources: [
        .copy("runtime"),
        .copy("com.qvacua.NvimView.vim"),
        .copy("NvimServer"),
      ]
    ),
    .testTarget(
      name: "NvimViewTests",
      dependencies: ["NvimView"]
    ),
  ]
)
