// swift-tools-version:5.7

import PackageDescription

let package = Package(
  name: "NvimServer",
  platforms: [.macOS(.v13)],
  products: [
    .library(name: "NvimServerTypes", targets: ["NvimServerTypes"]),
  ],
  dependencies: [],
  targets: [
    .target(name: "NvimServerTypes", dependencies: [], path: "NvimServerTypes"),
    .executableTarget(
      name: "NvimServer",
      dependencies: [],
      path: "NvimServer/Sources",
      cSettings: [
        // Otherwise we get typedef redefinition error due to double definition of Boolean
        .unsafeFlags(["-fno-modules"]),
        .define("INCLUDE_GENERATED_DECLARATIONS", to: "1"),
        // The target folder is the working directory.
        .headerSearchPath("../../NvimServer/neovim/src"),
        .headerSearchPath("../../NvimServer/neovim/build/include"),
        .headerSearchPath("../../NvimServer/neovim/.deps/usr/include"),
        .headerSearchPath("../../NvimServer/neovim/build/cmake.config"),
        .headerSearchPath("../../NvimServer/neovim/build/src/nvim/auto/"),
        .headerSearchPath("../../NvimServer/third-party/gettext/include"),
        .headerSearchPath("../../NvimServer/third-party/lua/include/lua"),
      ],
      linkerSettings: [
        .linkedFramework("CoreServices"),
        .linkedFramework("CoreFoundation"),
        .linkedLibrary("util"),
        .linkedLibrary("m"),
        .linkedLibrary("dl"),
        .linkedLibrary("pthread"),
        .linkedLibrary("iconv"),
        .unsafeFlags([
          // These paths seem to depend on where swift build is executed. Xcode does it in the
          // folder where Package.swift is located.
          "../neovim/build/lib/libnvim.a",
          "../neovim/.deps/usr/lib/libmsgpack-c.a",
          "../neovim/.deps/usr/lib/libluv.a",
          "../neovim/.deps/usr/lib/liblpeg.a",
          "../neovim/.deps/usr/lib/libtermkey.a",
          "../neovim/.deps/usr/lib/libuv.a",
          "../neovim/.deps/usr/lib/libunibilium.a",
          "../neovim/.deps/usr/lib/libvterm.a",
          "../neovim/.deps/usr/lib/libluajit-5.1.a",
          "../neovim/.deps/usr/lib/libtree-sitter.a",
          "NvimServer/third-party/gettext/lib/libintl.a",
        ]),
      ]
    ),
  ],
  cLanguageStandard: .gnu99
)
