import PackageDescription

let package = Package(
  name: "express-simple",
  dependencies: [
    .Package(url: "../..",
             majorVersion: 0, minor: 0)
  ]
)
