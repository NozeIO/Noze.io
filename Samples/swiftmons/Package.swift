import PackageDescription

let package = Package(
  name: "swiftmons",
  dependencies: [
    .Package(url: "../..",
             majorVersion: 0, minor: 3)
  ]
)
