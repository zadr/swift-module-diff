import ArgumentParser
import Foundation

@main
struct Compare: ParsableCommand {
	static var configuration = CommandConfiguration(
		abstract: "A utility for diffing two Swift APIs",
		version: "0.1.0"
	)

	@Option(name: .shortAndLong, help: "Path to the older API. Default: /Applications/Xcode.app")
	var old: String = "/Applications/Xcode.app"

	@Option(name: .shortAndLong, help: "Path to the newer API. Default: /Applications/Xcode-beta.app")
	var new: String = "/Applications/Xcode-beta.app"

	@Option(name: .long, help: "Path to output results. Default: ~/Desktop/swiftmodule-diff/")
	var output: String = "~/Desktop/swiftmodule-diff/"

	mutating func run() throws {
		print(Date())

		let oldFrameworks = frameworks(for: old)
		let newFrameworks = frameworks(for: new)

		print(Date())
	}

	func frameworks(for path: String) -> [SwiftmoduleFinder.Platform: [SwiftmoduleFinder.Architecture: Set<Framework>]] {
		let modules = SwiftmoduleFinder(app: path).run()

		var results = [SwiftmoduleFinder.Platform: [SwiftmoduleFinder.Architecture: Set<Framework>]]()
		for (platform, architectureToModules) in modules {
			print(platform)

			var platformSDKs = [SwiftmoduleFinder.Architecture: Set<Framework>]()
			for (architecture, moduleList) in architectureToModules {
				print(architecture)

				var architectureFrameworks = Set<Framework>()
//				DispatchQueue.concurrentPerform(iterations: moduleList.count) { i in
				for i in 0 ..< moduleList.count {
					let module = moduleList[i]
					print(module.absoluteString)

					let path = module.absoluteString.replacingOccurrences(of: "file://", with: "")
					var framework = ParseSwiftmodule(path: path).run()
					framework.name =
					(
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
