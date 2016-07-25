import PackageDescription

let package = Package(
  name: "httpd-helloworld",
  dependencies: [
    .Package(url: "../..",
             majorVersion: 0, minor: 3)
  ]
)
