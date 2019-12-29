// swift-tools-version:4.2
import PackageDescription

let package = Package(
  name:     "cows2code",
  products: [
    .executable(name: "cows2code", targets: [ "cows2code" ]),
  ],
  dependencies: [
    .package(url: "../..", from: "0.6.5")
  ],
  targets: [
    .target(name: "cows2code", 
            dependencies: [ "streams", "fs", "process", "console" ],
            path: ".")
  ]
)
