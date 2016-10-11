import PackageDescription

let package = Package(
  name: "sleep",
  dependencies: [
    .Package(url: "../..",
             majorVersion: 0, minor: 5)
  ]
)
