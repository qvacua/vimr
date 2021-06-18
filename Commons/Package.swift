// swift-tools-version:5.3

import PackageDescription

let package = Package(
  name: "Commons",
  platforms: [.macOS(.v10_13)],
  products: [
    .library(name: "Commons", targets: ["Commons", "CommonsObjC"]),
  ],
  dependencies: [
    .package(url: "https://github.com/Quick/Nimble", .upToNextMinor(from: "9.2.0")),
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
