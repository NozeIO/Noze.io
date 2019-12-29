// swift-tools-version:4.2
import PackageDescription

let package = Package(
  name:     "todo-mvc",
  products: [
    .executable(name: "todo-mvc", targets: [ "todo-mvc" ]),
  ],
  dependencies: [
    .package(url: "../..", from: "0.6.5")
  ],
  targets: [
    .target(name: "todo-mvc", 
            dependencies: [ "Freddy", "express" ],
            path: ".")
  ]
)
