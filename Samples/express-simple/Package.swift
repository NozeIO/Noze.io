// swift-tools-version:4.2
import PackageDescription

let package = Package(
  name:     "express-simple",
  products: [
    .executable(name: "express-simple", targets: [ "express-simple" ]),
  ],
  dependencies: [
    .package(url: "../..", from: "0.6.5")
  ],
  targets: [
    .target(name: "express-simple", 
            dependencies: [ "streams", "express", "cows" ],
            path: "Sources")
  ]
)
