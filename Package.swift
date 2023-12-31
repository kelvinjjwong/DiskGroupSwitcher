// swift-tools-version: 5.8
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "DiskGroupSwitcher",
    platforms: [
        .macOS(.v11)
    ],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .executable(
            name: "DiskGroupSwitcher",
            targets: ["DiskGroupSwitcher"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
        .package(url: "https://github.com/kelvinjjwong/LoggerFactory", from: "1.1.1")
        .package(url: "https://github.com/swhitty/FlyingFox.git", .upToNextMajor(from: "0.13.0"))
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "DiskGroupSwitcher",
            dependencies: ["LoggerFactory", "FlyingFox", "FlyingSocks"]),
        .testTarget(
            name: "DiskGroupSwitcherTests",
            dependencies: ["DiskGroupSwitcher", "LoggerFactory", "FlyingFox", "FlyingSocks"]),
    ],
    swiftLanguageVersions: [.v5]
)
