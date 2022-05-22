// swift-tools-version:5.6

import PackageDescription

let package = Package(
  name: "NvimView",
  platforms: [.macOS(.v10_13)],
  products: [
    .library(name: "NvimView", targets: ["NvimView"]),
  ],
  dependencies: [
    .package(url: "https://github.com/a2/MessagePack.swift", from: "4.0.0"),
    .package(url: "https://github.com/ReactiveX/RxSwift", from: "6.5.0"),
    .package(url: "https://github.com/Quick/Nimble", from: "10.0.0"),
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
        .product(name: "MessagePack", package: "MessagePack.swift"),
        "Commons",
      ],
      // com.qvacua.NvimView.vim is copied by the download NvimServer script.
      exclude: ["Resources/com.qvacua.NvimView.vim"],
      resources: [
        .copy("Resources/runtime"),
        .copy("Resources/NvimServer"),
      ]
    ),
    .testTarget(name: "NvimViewTests", dependencies: ["NvimView", "Nimble"]),
  ]
)
