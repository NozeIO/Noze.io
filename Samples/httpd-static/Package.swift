// swift-tools-version:4.2
import PackageDescription

let package = Package(
  name:     "httpd-static",
  products: [
    .executable(name: "httpd-static", targets: [ "httpd-static" ]),
  ],
  dependencies: [
    .package(url: "../..", from: "0.6.5")
  ],
  targets: [
    .target(name: "httpd-static", 
            dependencies: [ "console", "fs", "http", "process" ],
            path: "Sources")
  ]
)
