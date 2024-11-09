// swift-tools-version: 5.9

import PackageDescription

let package = Package(
  name: "RxPack",
  platforms: [.macOS(.v12)],
  products: [
    .library(name: "RxPack", targets: ["RxPack"]),
    .library(name: "RxNeovim", targets: ["RxNeovim"]),
  ],
  dependencies: [
    .package(url: "https://github.com/ReactiveX/RxSwift", from: "6.8.0"),
    .package(url: "https://github.com/qvacua/MessagePack.swift", .upToNextMinor(from: "4.1.0")),
    .package(url: "https://github.com/Quick/Nimble", from: "13.4.0"),
  ],
  targets: [
    .target(name: "RxPack", dependencies: [
      .product(name: "RxSwift", package: "RxSwift"),
      .product(name: "MessagePack", package: "MessagePack.swift"),
    ]),
    .testTarget(name: "RxPackTests", dependencies: [
      "RxPack",
      .product(name: "RxBlocking", package: "RxSwift"),
      .product(name: "RxTest", package: "RxSwift"),
      .product(name: "Nimble", package: "Nimble"),
    ]),
    .target(
      name: "RxNeovim",
      dependencies: [
        .product(name: "RxSwift", package: "RxSwift"),
        "RxPack",
        .product(name: "MessagePack", package: "MessagePack.swift"),
      ]
    ),
    .testTarget(
      name: "RxNeovimTests",
      dependencies: [
        "RxNeovim",
        .product(name: "RxBlocking", package: "RxSwift"),
        .product(name: "Nimble", package: "Nimble"),
      ]
    ),
  ]
)
