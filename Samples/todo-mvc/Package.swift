import PackageDescription

let package = Package(
  name: "todo-mvc",
  dependencies: [
    .Package(url: "../..",
             majorVersion: 0, minor: 1)
  ]
)
