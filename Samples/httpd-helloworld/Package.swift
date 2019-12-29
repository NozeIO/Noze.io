// swift-tools-version:4.2
import PackageDescription

let package = Package(
  name:     "httpd-helloworld",
  products: [
    .executable(name: "httpd-helloworld", targets: [ "httpd-helloworld" ]),
  ],
  dependencies: [
    .package(url: "../..", from: "0.6.5")
  ],
  targets: [
    .target(name: "httpd-helloworld", 
            dependencies: [ "http" ],
            path: ".")
  ]
)
