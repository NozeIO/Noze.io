// swift-tools-version:4.2
import PackageDescription

let package = Package(
  name:     "echozd",
  products: [
    .executable(name: "echozd", targets: [ "echozd" ]),
  ],
  dependencies: [
    .package(url: "../..", from: "0.6.5")
  ],
  targets: [
    .target(name: "echozd", 
            dependencies: [ "net" ],
            path: ".")
  ]
)
