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
    .package(url: "https://github.com/SimplyDanny/SwiftLintPlugins", from: "0.62.1"),
  ],
  targets: [
    .target(
      name: "Commons",
      dependencies: [],
      plugins: [.plugin(name: "SwiftLintBuildToolPlugin", package: "SwiftLintPlugins")]
    ),
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
