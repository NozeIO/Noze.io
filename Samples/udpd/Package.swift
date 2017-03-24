import PackageDescription

let package = Package(
  name: "udpd",
  dependencies: [
    .Package(url: "../..",
             majorVersion: 0, minor: 5)
  ]
)
