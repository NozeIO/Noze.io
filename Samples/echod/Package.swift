import PackageDescription

let package = Package(
  name: "echod",
  dependencies: [
    .Package(url: "../..",
             majorVersion: 0, minor: 3)
  ]
)
