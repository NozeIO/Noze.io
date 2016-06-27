import PackageDescription

let package = Package(
  name: "cows2code",
  dependencies: [
    .Package(url: "../..",
             majorVersion: 0, minor: 2)
  ]
)
