import PackageDescription

let package = Package(
  name: "echozd",
  dependencies: [
    .Package(url: "../..",
             majorVersion: 0, minor: 2)
  ]
)
