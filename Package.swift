// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "swift-module-diff",
    platforms: [.macOS(.v14)],
	dependencies: [
	    .package(url: "https://github.com/apple/swift-argument-parser.git", .upToNextMajor(from: "1.2.0")),
		.package(url: "https://github.com/apple/swift-syntax.git", branch: "509.0.2"),
	],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .executableTarget(
            name: "swift-module-diff",
			dependencies: [
			    .product(name: "ArgumentParser", package: "swift-argument-parser"),
				.product(name: "SwiftParser", package: "swift-syntax"),
				.product(name: "SwiftSyntax", package: "swift-syntax"),
			],
			path: "Code",
            swiftSettings: [.enableUpcomingFeature("BareSlashRegexLiterals")]
		),
    ]
)
