import PackageDescription

let package = Package(
  name: "httpd-cookies",
  dependencies: [
    .Package(url: "../..",
             majorVersion: 0, minor: 5)
  ]
)
