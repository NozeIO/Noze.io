// swift-tools-version:4.2
import PackageDescription

let package = Package(
  name:     "swiftmons",
  products: [
    .executable(name: "swiftmons", targets: [ "swiftmons" ]),
  ],
  dependencies: [
    .package(url: "../..", from: "0.6.5")
  ],
  targets: [
    .target(name: "swiftmons", 
            dependencies: [ "fs", "child_process", "process", "console" ],
            path: "Sources")
  ]
)
