import Foundation
import os

typealias Summary = [SwiftmoduleFinder.Platform: [SwiftmoduleFinder.Architecture: Set<Framework>]]
typealias FrameworkIndex = [SwiftmoduleFinder.Platform: [SwiftmoduleFinder.Architecture: [String: Framework]]]

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

		let threadCount = ProcessInfo.processInfo.activeProcessorCount
		var resultsPerThread = (0..<threadCount).map { _ -> Summary in [:] }

		DispatchQueue.concurrentPerform(iterations: everything.count) { i in
			let it = everything[i]
			if progress { print("\(it.platform) \(it.architecture) \(it.url)") }

			let path = it.url.path(percentEncoded: false)
			var framework = ParseSwiftmodule(path: path, typePrefixesToRemove: qualifiedTypePrefixesToRemove).run()

			// Merge duplicate extensions (e.g., "extension Never: A" + "extension Never: B" → "extension Never: A, B")
			framework.mergeExtensions()

			let threadIndex = i % threadCount
			resultsPerThread[threadIndex][it.platform, default: [:]][it.architecture, default: []].insert(framework)
		}

		for threadResults in resultsPerThread {
			for (platform, architectures) in threadResults {
				for (architecture, frameworks) in architectures {
					results[platform, default: [:]][architecture, default: []].formUnion(frameworks)
				}
			}
		}

		return results
	}

	static func buildFrameworkIndex(from summary: Summary) -> FrameworkIndex {
		var index = FrameworkIndex()

		for (platform, architectures) in summary {
			var archIndex: [SwiftmoduleFinder.Architecture: [String: Framework]] = [:]
			for (architecture, frameworks) in architectures {
				var frameworkDict: [String: Framework] = [:]
				for framework in frameworks {
					frameworkDict[framework.name] = framework
				}
				archIndex[architecture] = frameworkDict
			}
			index[platform] = archIndex
		}

		return index
	}
}
