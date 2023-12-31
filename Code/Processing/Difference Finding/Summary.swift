import Foundation

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
		for (platform, architectureToModules) in SwiftmoduleFinder(app: path).run() {
			if progress { print(platform) }

			var platformSDKs = [SwiftmoduleFinder.Architecture: Set<Framework>]()
			for (architecture, moduleList) in architectureToModules {
				if progress { print(architecture) }

				var architectureFrameworks = Set<Framework>()
				for i in 0 ..< moduleList.count {
					let module = moduleList[i]
					if progress { print(module.absoluteString) }

					let path = module.absoluteString.replacingOccurrences(of: "file://", with: "")
					let framework = ParseSwiftmodule(path: path, typePrefixesToRemove: typePrefixesToRemove).run()

					architectureFrameworks.insert(framework)
				}

				if !architectureFrameworks.isEmpty {
					platformSDKs[architecture] = architectureFrameworks
				}
			}

			if !platformSDKs.isEmpty {
				results[platform] = platformSDKs
			}
		}

		return results
	}
}
