// swift-tools-version:4.2
import PackageDescription

let package = Package(
  name:     "httpd-cookies",
  products: [
    .executable(name: "httpd-cookies", targets: [ "httpd-cookies" ]),
  ],
  dependencies: [
    .package(url: "../..", from: "0.6.5")
  ],
  targets: [
    .target(name: "httpd-cookies", 
            dependencies: [ "xsys", "http" ],
            path: ".")
  ]
)
