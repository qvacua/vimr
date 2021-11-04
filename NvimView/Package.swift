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
    .package(url: "https://github.com/ReactiveX/RxSwift", .upToNextMinor(from: "6.2.0")),
    .package(url: "https://github.com/Quick/Nimble", .upToNextMinor(from: "9.2.1")),
    .package(name: "NvimServer", path: "../NvimServer"),
    .package(name: "RxPack", path: "../RxPack"),
    .package(name: "Commons", path: "../Commons"),
    .package(name: "Tabs", path: "../Tabs"),
  ],
  targets: [
    .target(
      name: "NvimView",
      dependencies: [
        "RxSwift",
        "RxPack",
        "Tabs",
        .product(name: "NvimServerTypes", package: "NvimServer"),
        "MessagePack",
        "Commons",
      ],
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
