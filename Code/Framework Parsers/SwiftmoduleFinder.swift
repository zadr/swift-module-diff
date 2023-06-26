import Foundation

struct SwiftmoduleFinder {
	typealias Architecture = String

	enum Platform: String, CaseIterable, Equatable, Hashable {
		case iOS
		case driverKit
		case macOS
		case tvOS
		case watchOS
		case xrOS

		var paths: [String] {
			switch self {
			case .iOS: [
				"Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS.sdk/System/Library/Frameworks",
				"Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS.sdk/usr/lib/swift",
				"Contents/Developer/Platforms/iPhoneOS.platform/Developer/usr/lib" // find XCTest changes
			]
			case .driverKit: [
				"Contents/Developer/Platforms/DriverKit.platform/Developer/SDKs/DriverKit.sdk/System/DriverKit/System/Library/Frameworks",
			]
			case .macOS: [
				"Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/iPhoneOS.sdk/System/Library/Frameworks",
				"Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/lib/swift",
				"Contents/Developer/Platforms/MacOSX.platform/Developer/usr/lib" // find XCTest changes
			]
			case .tvOS: [
				"Contents/Developer/Platforms/AppleTVOS.platform/Developer/SDKs/AppleTVOS.sdk/System/Library/Frameworks",
				"Contents/Developer/Platforms/AppleTVOS.platform/Developer/SDKs/AppleTVOS.sdk/usr/lib/swift",
				"Contents/Developer/Platforms/AppleTVOS.platform/Developer/usr/lib" // find XCTest changes
			]
			case .watchOS: [
				"Contents/Developer/Platforms/WatchOS.platform/Developer/SDKs/iPhoneOS.sdk/System/Library/Frameworks",
				"Contents/Developer/Platforms/WatchOS.platform/Developer/SDKs/WatchOS.sdk/usr/lib/swift",
				"Contents/Developer/Platforms/WatchOS.platform/Developer/usr/lib" // find XCTest changes
			]
			case .xrOS: [
				"Contents/Developer/Platforms/XROS.platform/Developer/SDKs/iPhoneOS.sdk/System/Library/Frameworks",
				"Contents/Developer/Platforms/XROS.platform/Developer/SDKs/WatchOS.sdk/usr/lib/swift",
				"Contents/Developer/Platforms/XROS.platform/Developer/usr/lib" // find XCTest changes
			]
			}
		}
	}

	let app: String

	init(app: String) {
		self.app = app
	}

	func run() -> [Platform: [Architecture: [URL]]] {
		autoreleasepool {
			var result = [Platform: [Architecture: [URL]]]()
			for platform in Platform.allCases {
				let fileManager = FileManager()
				for path in platform.paths {
					let enumerator = fileManager.enumerator(atPath: app + "/" + path)
					while let fileName = enumerator?.nextObject() as? String {
						if fileName.hasSuffix("swiftinterface") {
							let completePath = "\(app)/\(path)/\(fileName)"
							let architecture = Architecture(completePath.components(separatedBy: "/").last!.components(separatedBy: "-").first!)
							var outer = result[platform] ?? [Architecture: [URL]]()
							var inner = outer[architecture] ?? [URL]()
							inner += [URL(filePath: completePath)]
							outer[architecture] = inner
							result[platform] = outer
						}
					}
				}
			}

			return result
		}
	}
}
