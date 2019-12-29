// swift-tools-version:4.2
import PackageDescription

let package = Package(
  name:     "call-git",
  products: [
    .executable(name: "call-git", targets: [ "call-git" ]),
  ],
  dependencies: [
    .package(url: "../..", from: "0.6.5")
  ],
  targets: [
    .target(name: "call-git", 
            dependencies: [ "streams", "child_process", "process" ],
            path: ".")
  ]
)
