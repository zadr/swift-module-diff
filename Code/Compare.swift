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
		var frameworks = Set<Framework>()

		let paths = [ old, new ]
		for path in paths {
			let modules = SwiftmoduleFinder(app: path).run()
			for (platform, architectureToModules) in modules {
				print(platform)
		
				for (architecture, moduleList) in architectureToModules {
					print(architecture)
		
					for module in moduleList {
						print(module.absoluteString)
		
						let path = module.absoluteString.replacingOccurrences(of: "file://", with: "")
						let framework = ParseSwiftmodule(path: path).run()
						frameworks.insert(framework)
					}
				}
			}
		}
		print(Date())
		let json = try JSONEncoder().encode(frameworks)
		try json.write(to: URL(filePath: (output as NSString).expandingTildeInPath + "/blob.json"))
		print(Date())
	}
}
