import PackageDescription

let package = Package(
  name: "miniirc",
  dependencies: [
    .Package(url: "../..",
             majorVersion: 0, minor: 1)
  ]
)
