import Foundation
import os

typealias Summary = [SwiftmoduleFinder.Platform: [SwiftmoduleFinder.Architecture: Set<Framework>]]

extension Summary {
	static func listFrameworks(for path: String, progress: Bool) -> Set<String> {
		var results = Set<String>()
		for (platform, architectureToModules) in SwiftmoduleFinder(app: path).run() {
			if progress { print(platform) }

			for (architecture, moduleList) in architectureToModules {
				if progress { print(architecture) }

				for i in 0 ..< moduleList.count {
					if progress { print(moduleList[i].absoluteString) }
					// go from `file:///path/to/Framework.swiftmodule/arm64-apple-ios.swiftinterface` to `Framework`
					results.insert(
						(
							(
								(
									moduleList[i].absoluteString as NSString
								).deletingLastPathComponent as NSString
							).lastPathComponent as NSString
						).deletingPathExtension
					)
				}
			}
		}

		return results
	}

	struct AllOfIt {
		let platform: SwiftmoduleFinder.Platform
		let architecture: SwiftmoduleFinder.Architecture
		let url: URL
	}

	static func createSummary(for path: String, typePrefixesToRemove: [String], progress: Bool) -> Summary {
		var results = Summary()
		let qualifiedTypePrefixesToRemove = typePrefixesToRemove.map { $0 + "." }

		var everything = [AllOfIt]()
		for (platform, architectureToModules) in SwiftmoduleFinder(app: path).run() {
			results[platform] = [SwiftmoduleFinder.Architecture: Set<Framework>]()

			for (architecture, moduleList) in architectureToModules {
				results[platform]![architecture] = Set<Framework>()

				for module in moduleList {
					everything.append(AllOfIt(platform: platform, architecture: architecture, url: module))
				}
			}
		}

		let lock = OSAllocatedUnfairLock()
		DispatchQueue.concurrentPerform(iterations: everything.count) { i in
			let it = everything[i]
			if progress { print("\(it.platform) \(it.architecture) \(it.url)") }

			let path = it.url.absoluteString.replacingOccurrences(of: "file://", with: "")
			let framework = ParseSwiftmodule(path: path, typePrefixesToRemove: qualifiedTypePrefixesToRemove).run()

			lock.lock()
			var p = results[it.platform]
			var a = p?[it.architecture]
			a?.insert(framework)
			p?[it.architecture] = a
			results[it.platform] = p
			lock.unlock()
		}

		return results
	}
}
