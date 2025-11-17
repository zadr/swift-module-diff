// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "swift-module-diff",
    platforms: [.macOS(.v14)],
	dependencies: [
	    .package(url: "https://github.com/apple/swift-argument-parser.git", .upToNextMajor(from: "1.6.2")),
	    .package(url: "https://github.com/swiftlang/swift-syntax.git", branch: "release/6.3"),
	],
    targets: [
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
