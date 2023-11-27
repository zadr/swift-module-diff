import Foundation

typealias Summary = [SwiftmoduleFinder.Platform: [SwiftmoduleFinder.Architecture: Set<Framework>]]

extension Summary {
	static func createSummary(for path: String, trace: Bool) -> Summary {
		let modules = SwiftmoduleFinder(app: path).run()

		var results = Summary()
		for (platform, architectureToModules) in modules {
			if trace { print(platform) }

			var platformSDKs = [SwiftmoduleFinder.Architecture: Set<Framework>]()
			for (architecture, moduleList) in architectureToModules {
				if trace { print(architecture) }

				var architectureFrameworks = Set<Framework>()
				for i in 0 ..< moduleList.count {
					let module = moduleList[i]
					if trace { print(module.absoluteString) }

					let path = module.absoluteString.replacingOccurrences(of: "file://", with: "")
					var framework = ParseSwiftmodule(path: path).run()
					framework.name = (
						(
							(
								module.absoluteString as NSString
							).deletingLastPathComponent as NSString
						).lastPathComponent as NSString
					).deletingPathExtension

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
