import PackageDescription

let package = Package(
        name: "crazy8sbot",
        dependencies: [
                         .Package(url: "../CIRCBot", majorVersion: 0, minor: 2),
                      ]
)

