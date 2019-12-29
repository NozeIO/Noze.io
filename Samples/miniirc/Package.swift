// swift-tools-version:4.2
import PackageDescription

let package = Package(
  name:     "miniirc",
  products: [
    .executable(name: "miniirc", targets: [ "miniirc" ]),
  ],
  dependencies: [
    .package(url: "../..", from: "0.6.5")
  ],
  targets: [
    .target(name: "miniirc", 
            dependencies: [ "streams", "net", "leftpad" ],
            path: ".")
  ]
)
