import PackageDescription

let package = Package(
  name: "call-git",
  dependencies: [
    .Package(url: "../..",
             majorVersion: 0, minor: 1)
  ]
)
