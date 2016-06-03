import PackageDescription

let package = Package(
  name: "httpd-static",
  dependencies: [
    .Package(url: "../..",
             majorVersion: 0, minor: 2)
  ]
)
