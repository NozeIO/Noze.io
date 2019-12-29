// swift-tools-version:4.2
import PackageDescription

let package = Package(
  name:     "sleep",
  products: [
    .executable(name: "sleep", targets: [ "sleep" ]),
  ],
  dependencies: [
    .package(url: "../..", from: "0.6.5")
  ],
  targets: [
    .target(name: "sleep", dependencies: [ "core" ], path: ".")
  ]
)
