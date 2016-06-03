import PackageDescription

let package = Package(
  name: "connect-git",
  dependencies: [
    .Package(url: "../..",
             majorVersion: 0, minor: 0)
  ]
)
