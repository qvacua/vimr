// swift-tools-version: 6.0

import PackageDescription

let package = Package(
  name: "Commons",
  platforms: [.macOS(.v13)],
  products: [
    .library(name: "Commons", targets: ["Commons", "CommonsObjC"]),
  ],
  dependencies: [
    .package(url: "https://github.com/Quick/Nimble", from: "13.8.0"),
  ],
  targets: [
    .target(name: "Commons", dependencies: []),
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
