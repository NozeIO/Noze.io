import PackageDescription

let package = Package(
  name: "todo-mvc-redis",
  dependencies: [
    .Package(url: "../..",
             majorVersion: 0, minor: 5)
  ]
)
