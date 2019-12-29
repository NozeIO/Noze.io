// swift-tools-version:4.2
import PackageDescription

let package = Package(
  name:     "connect-git",
  products: [
    .executable(name: "connect-git", targets: [ "connect-git" ]),
  ],
  dependencies: [
    .package(url: "../..", from: "0.6.5")
  ],
  targets: [
    .target(name: "connect-git", 
            dependencies: [ "streams", "child_process", "process", "connect" ],
            path: ".")
  ]
)
