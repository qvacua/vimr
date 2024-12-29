// swift-tools-version: 6.0

import PackageDescription

let package = Package(
  name: "Commons",
  platforms: [.macOS(.v13)],
  products: [
    .library(name: "Commons", targets: ["Commons", "CommonsObjC"]),
  ],
  dependencies: [
    .package(url: "https://github.com/Quick/Nimble", from: "13.7.1"),
    .package(url: "https://github.com/ReactiveX/RxSwift", from: "6.8.0"),
  ],
  targets: [
    .target(name: "Commons", dependencies: [
      .product(name: "RxSwift", package: "RxSwift"),
    ]),
    .target(name: "CommonsObjC", dependencies: []),
    .testTarget(
      name: "CommonsTests",
      dependencies: ["Commons", "Nimble"],
      resources: [
        .copy("Resources"),
      ]
    ),
  ]
)
