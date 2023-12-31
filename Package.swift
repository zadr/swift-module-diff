// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "swift-module-diff",
    platforms: [.macOS(.v14)],
	dependencies: [
	    .package(url: "https://github.com/apple/swift-argument-parser.git", .upToNextMajor(from: "1.2.0")),
		.package(url: "https://github.com/apple/swift-syntax.git", branch: "509.0.2"),
		.package(url: "https://github.com/Kitura/swift-html-entities.git", from: "3.0.0"),
	],
    targets: [
        .executableTarget(
            name: "swift-module-diff",
			dependencies: [
			    .product(name: "ArgumentParser", package: "swift-argument-parser"),
				.product(name: "SwiftParser", package: "swift-syntax"),
				.product(name: "SwiftSyntax", package: "swift-syntax"),
				.product(name: "HTMLEntities", package: "swift-html-entities")
			],
			path: "Code",
            swiftSettings: [.enableUpcomingFeature("BareSlashRegexLiterals")]
		),
    ]
)
