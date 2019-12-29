// swift-tools-version:4.2
import PackageDescription

let package = Package(
  name:     "echod",
  products: [
    .executable(name: "echod", targets: [ "echod" ]),
  ],
  dependencies: [
    .package(url: "../..", from: "0.6.5")
  ],
  targets: [
    .target(name: "echod", 
            dependencies: [ "net" ],
            path: ".")
  ]
)
