// swift-tools-version:5.3

import PackageDescription

let package = Package(
  name: "NvimView",
  platforms: [.macOS(.v10_13)],
  products: [
    .library(name: "NvimView", targets: ["NvimView"]),
  ],
  dependencies: [
    .package(
      name: "MessagePack",
      url: "https://github.com/a2/MessagePack.swift",
      .upToNextMinor(from: "4.0.0")
    ),
    .package(url: "https://github.com/ReactiveX/RxSwift", .upToNextMinor(from: "5.1.1")),
    .package(url: "https://github.com/Quick/Nimble", .upToNextMinor(from: "8.1.1")),
    .package(name: "NvimServerTypes", path: "../NvimServer"),
    .package(name: "RxPack", path: "../RxPack"),
    .package(name: "Commons", path: "../Commons"),
    .package(name: "Tabs", path: "../Tabs"),
  ],
  targets: [
    .target(
      name: "NvimView",
      dependencies: ["RxSwift", "RxPack", "Tabs", "NvimServerTypes", "MessagePack", "Commons"],
      // com.qvacua.NvimView.vim is copied by the download NvimServer script.
      exclude: ["Resources/com.qvacua.NvimView.vim"],
      resources: [
        .copy("Resources/runtime"),
        .copy("Resources/NvimServer"),
      ]
    ),
    .testTarget(
      name: "NvimViewTests",
      dependencies: ["NvimView", "Nimble"]
    ),
  ]
)
