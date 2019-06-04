// swift-tools-version:4.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SwiftKnex",
    products: [
        .library(name: "SwiftKnex", targets: ["SwiftKnex"]),
        .executable(name: "SwiftKnexMigration", targets: ["SwiftKnexMigration"]),
    ],
    dependencies: [
        .package(url: "https://github.com/tuken/Prorsum.git", .branch("dev_tuken"))
    ],
    targets: [
        .target(name: "Mysql", dependencies: ["Prorsum"]),
        .target(name: "SwiftKnex", dependencies: ["Mysql"]),
        .target(name: "SwiftKnexMigration", dependencies: ["SwiftKnex", "Mysql"]),
        .testTarget(name: "SwiftKnexTests", dependencies: ["SwiftKnex", "Mysql"]),
    ]
)
