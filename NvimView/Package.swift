// swift-tools-version: 6.0

import PackageDescription

let package = Package(
  name: "NvimView",
  platforms: [.macOS(.v13)],
  products: [
    .library(name: "NvimView", targets: ["NvimView"]),
  ],
  dependencies: [
    .package(url: "https://github.com/qvacua/MessagePack.swift", from: "4.1.0"),
    .package(url: "https://github.com/Quick/Nimble", from: "13.7.1"),
    .package(name: "Commons", path: "../Commons"),
    .package(name: "Tabs", path: "../Tabs"),
    .package(name: "NvimApi", path: "../NvimApi"),
  ],
  targets: [
    .target(
      name: "NvimView",
      dependencies: [
        "Tabs",
        .product(name: "MessagePack", package: "MessagePack.swift"),
        "Commons",
        "NvimApi",
      ],
      // com.qvacua.NvimView.vim is copied by the build NvimServer script.
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
