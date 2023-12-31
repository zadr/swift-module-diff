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

	static func createSummary(for path: String, typePrefixesToRemove: Set<String>, progress: Bool) -> Summary {
		var results = Summary()
		let all = SwiftmoduleFinder(app: path).run()
		let keys = all.keys

		let typePrefixesToRemoveWithQualifier = Set(typePrefixesToRemove.map { $0 + "." })

		let lock = OSAllocatedUnfairLock()
		DispatchQueue.concurrentPerform(iterations: keys.count) { i in
			let platform = keys[all.keys.index(all.keys.startIndex, offsetBy: i)]
			let architectureToModules = all[platform]!
			if progress { print(platform) }

			var platformSDKs = [SwiftmoduleFinder.Architecture: Set<Framework>]()
			for (architecture, moduleList) in architectureToModules {
				if progress { print(architecture) }

				var architectureFrameworks = Set<Framework>()
				for i in 0 ..< moduleList.count {
					let module = moduleList[i]
					if progress { print(module.absoluteString) }

					let path = module.absoluteString.replacingOccurrences(of: "file://", with: "")
					let framework = ParseSwiftmodule(path: path, typePrefixesToRemove: typePrefixesToRemoveWithQualifier).run()

					architectureFrameworks.insert(framework)
				}

				if !architectureFrameworks.isEmpty {
					platformSDKs[architecture] = architectureFrameworks
				}
			}

			if !platformSDKs.isEmpty {
				lock.lock()
				results[platform] = platformSDKs
				lock.unlock()
			}
		}

		return results
	}
}
