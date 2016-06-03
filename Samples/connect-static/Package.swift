import PackageDescription

let package = Package(
  name: "connect-static",
  dependencies: [
    .Package(url: "../..",
             majorVersion: 0, minor: 0)
  ]
)
