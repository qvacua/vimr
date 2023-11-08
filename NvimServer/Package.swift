// swift-tools-version:5.7

import PackageDescription

let package = Package(
  name: "NvimServer",
  platforms: [.macOS(.v13)],
  products: [
    .library(name: "NvimServerTypes", targets: ["NvimServerTypes"]),
  ],
  dependencies: [],
  targets: [.target(name: "NvimServerTypes", dependencies: [], path: "NvimServerTypes")]
)
