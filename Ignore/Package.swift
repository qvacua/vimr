// swift-tools-version: 6.0

import PackageDescription

let package = Package(
  name: "Ignore",
  platforms: [.macOS(.v13)],
  products: [
    .library(name: "Ignore", targets: ["Ignore"]),
  ],
  dependencies: [
    .package(url: "https://github.com/qvacua/misc.swift", exact: "0.4.0"),
    .package(url: "https://github.com/Quick/Nimble", from: "13.8.0"),
    .package(url: "https://github.com/SimplyDanny/SwiftLintPlugins", from: "0.62.1"),
  ],
  targets: [
    .target(
      name: "Ignore",
      dependencies: [.product(name: "WildmatchC", package: "misc.swift")],
      plugins: [.plugin(name: "SwiftLintBuildToolPlugin", package: "SwiftLintPlugins")]
    ),
    .testTarget(
      name: "IgnoreTests",
      dependencies: ["Ignore", "Nimble"],
      resources: [.copy("Resources")]
    ),
  ]
)
