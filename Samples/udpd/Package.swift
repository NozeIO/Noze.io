// swift-tools-version:4.2
import PackageDescription

let package = Package(
  name:     "udpd",
  products: [
    .executable(name: "udpd", targets: [ "udpd" ]),
  ],
  dependencies: [
    .package(url: "../..", from: "0.6.5")
  ],
  targets: [
    .target(name: "udpd", 
            dependencies: [ "console", "dgram" ],
            path: ".")
  ]
)
