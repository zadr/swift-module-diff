import Foundation

struct SwiftmoduleFinder {
	enum Architecture:  Equatable, Hashable {
		case arm64
		case arm64e
		case arm64_32
		case armv7k
		case other(String)

		init(string: String) {
			if string == "arm64" { self = .arm64 }
			else if string == "arm64e" { self = .arm64e }
			else if string == "arm64_32" { self = .arm64_32 }
			else if string == "armv7k" { self = .armv7k }
			else { self = .other(string) }
		}

		var name: String {
			switch self {
			case .arm64: return "arm64"
			case .arm64e: return "arm64e"
			case .arm64_32: return "arm64_32"
			case .armv7k: return "armv7k"
			case .other(let string): return string
			}
		}
	}

	enum Platform: CaseIterable, Equatable, Hashable {
		case iOS
		case macOS
		case tvOS
		case watchOS

		var paths: [String] {
			switch self {
			case .iOS: return [
				"Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS.sdk/System/Library/Frameworks",
				"Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS.sdk/usr/lib/swift",
				"Contents/Developer/Platforms/iPhoneOS.platform/Developer/usr/lib" // find XCTest changes
			]
			case .macOS: return [
				"Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/iPhoneOS.sdk/System/Library/Frameworks",
				"Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/lib/swift",
				"Contents/Developer/Platforms/MacOSX.platform/Developer/usr/lib" // find XCTest changes
			]
			case .tvOS: return [
				"Contents/Developer/Platforms/AppleTVOS.platform/Developer/SDKs/AppleTVOS.sdk/System/Library/Frameworks",
				"Contents/Developer/Platforms/AppleTVOS.platform/Developer/SDKs/AppleTVOS.sdk/usr/lib/swift",
				"Contents/Developer/Platforms/AppleTVOS.platform/Developer/usr/lib" // find XCTest changes
			]
			case .watchOS: return [
				"Contents/Developer/Platforms/WatchOS.platform/Developer/SDKs/iPhoneOS.sdk/System/Library/Frameworks",
				"Contents/Developer/Platforms/WatchOS.platform/Developer/SDKs/WatchOS.sdk/usr/lib/swift",
				"Contents/Developer/Platforms/WatchOS.platform/Developer/usr/lib" // find XCTest changes
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
							let architecture = Architecture(string: completePath.components(separatedBy: "/").last!.components(separatedBy: "-").first!)
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
