// swift-tools-version:4.2
import PackageDescription

let package = Package(
  name:     "connect-static",
  products: [
    .executable(name: "connect-static", targets: [ "connect-static" ]),
  ],
  dependencies: [
    .package(url: "../..", from: "0.6.5")
  ],
  targets: [
    .target(name: "connect-static", 
            dependencies: [ "streams", "http", "process", "connect" ],
            path: "Sources")
  ]
)
