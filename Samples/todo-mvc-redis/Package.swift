// swift-tools-version:4.2
import PackageDescription

let package = Package(
  name:     "todo-mvc-redis",
  products: [
    .executable(name: "todo-mvc-redis", targets: [ "todo-mvc-redis" ]),
  ],
  dependencies: [
    .package(url: "../..", from: "0.6.5")
  ],
  targets: [
    .target(name: "todo-mvc-redis", 
            dependencies: [ "console", "redis", "express", "Freddy" ],
            path: ".")
  ]
)
