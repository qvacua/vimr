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
    .package(
      name: "NvimServerTypes",
      path: "../NvimServer/NvimServerTypes"
    ),
    .package(name: "RxPack", path: "../RxPack"),
    .package(name: "Commons", path: "../Commons"),
    .package(url: "https://github.com/Quick/Nimble", .upToNextMinor(from: "8.1.1")),
  ],
  targets: [
    .target(
      name: "NvimView",
      dependencies: ["RxSwift", "RxPack", "NvimServerTypes", "MessagePack", "Commons"],
      // com.qvacua.NvimView.vim is copied by the download NvimServer script.
      exclude: ["com.qvacua.NvimView.vim"],
      resources: [
        .copy("runtime"),
        .copy("NvimServer"),
      ]
    ),
    .testTarget(
      name: "NvimViewTests",
      dependencies: ["NvimView", "Nimble"]
    ),
  ]
)
