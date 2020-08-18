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
    .package(name: "NvimServerTypes", url: "https://github.com/qvacua/neovim", .exact("0.1.0-types")),
  ],
  targets: [
    .target(
      name: "NvimView",
      dependencies: ["RxSwift", "MessagePack", "Socket", "NvimServerTypes"],
      // com.qvacua.NvimView.vim is copied by the download NvimServer script.
      exclude: ["com.qvacua.NvimView.vim"],
      resources: [
        .copy("runtime"),
        .copy("NvimServer"),
      ]
    ),
    .testTarget(
      name: "NvimViewTests",
      dependencies: ["NvimView"]
    ),
  ]
)
