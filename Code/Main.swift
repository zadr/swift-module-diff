import ArgumentParser
import Foundation

enum Format: String {
	case html
	case json
}

@main
struct Main: ParsableCommand {
	static var configuration = CommandConfiguration(
		abstract: "A utility for diffing two Swift APIs",
		version: "0.1.0"
	)

	@Option(name: .shortAndLong, help: "Path to the older API. Default: /Applications/Xcode.app")
	var old: String = "/Applications/Xcode-14rc.app"

	@Option(name: .shortAndLong, help: "Path to the newer API. Default: /Applications/Xcode-beta.app")
	var new: String = "/Applications/Xcode-15b3.app"

	@Option(name: .long, help: "Path to output results. Default: ~/Desktop/swiftmodule-diff/")
	var output: String = "~/Desktop/swiftmodule-diff/"

	@Option(name: .shortAndLong, help: "Print diff to console. May be combined with --html or --json. Default: true")
	var console: Bool = true

	@Option(name: .shortAndLong, help: "Write html to output directory. May be combined with --json or --console. Default: false.")
	var html: Bool = false

		let oldFrameworks = frameworks(for: old)
		let newFrameworks = frameworks(for: new)

		let platformChanges = Change.platformChanges(from: oldFrameworks, to: newFrameworks)
		for platformChange in platformChanges where platformChange.0 == .added {
			if verbose { print("New: \(platformChange.1)") }
			let newArchitectures = Change.architecturalChanges(
				from: [],
				to: Array(newFrameworks[platformChange.1]?.keys.compactMap { $0 } ?? [])
			)
			if verbose { print(newArchitectures) }
			for architecture in newArchitectures {
				let frameworks = Change.frameworkChanges(from: [], to: newFrameworks[platformChange.1]![architecture.1]!)
				for framework in frameworks {
					if verbose { print(framework.1.name) }
				}
			}
			if verbose { print("-----") }
		}
		for platformChange in platformChanges where platformChange.0 == .unchanged || platformChange.0 == .modified {
			if verbose { print("\(platformChange.0): \(platformChange.1)") }
			if verbose { print(Change.architecturalChanges(
				from: Array(oldFrameworks[platformChange.1]?.keys.compactMap { $0 } ?? []),
				to: Array(newFrameworks[platformChange.1]?.keys.compactMap { $0 } ?? []))
			) }
			if verbose { print("-----") }
		}
		for platformChange in platformChanges where platformChange.0 == .removed {
			if verbose { print("Gone: \(platformChange.1)") }
			if verbose { print(Change.architecturalChanges(
				from: Array(oldFrameworks[platformChange.1]?.keys.compactMap { $0 } ?? []),
				to: [])
			) }
			if verbose { print("-----") }
		}
	}
	@Option(name: .shortAndLong, help: "Write json to output directory. May be combined with --html or --console. Default: false")
	var json: Bool = false

	func frameworks(for path: String) -> [SwiftmoduleFinder.Platform: [SwiftmoduleFinder.Architecture: Set<Framework>]] {
		let modules = SwiftmoduleFinder(app: path).run()
	@Option(name: .shortAndLong, help: "Print trace output to console. Default: false")
	var trace: Bool = false

		var results = [SwiftmoduleFinder.Platform: [SwiftmoduleFinder.Architecture: Set<Framework>]]()
		for (platform, architectureToModules) in modules {
			if verbose { print(platform) }

			var platformSDKs = [SwiftmoduleFinder.Architecture: Set<Framework>]()
			for (architecture, moduleList) in architectureToModules {
				if verbose { print(architecture) }

				var architectureFrameworks = Set<Framework>()
				for i in 0 ..< moduleList.count {
					let module = moduleList[i]
					if verbose { print(module.absoluteString) }

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
	mutating func run() throws {
		if trace { print("Start: \(Date())") }

				if !architectureFrameworks.isEmpty {
					platformSDKs[architecture] = architectureFrameworks
				}
			}

			if !platformSDKs.isEmpty {
				results[platform] = platformSDKs
			}
		}

		return results
		if trace { print("End: \(Date())") }
	}
}
