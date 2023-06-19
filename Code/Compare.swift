import ArgumentParser
import Foundation

@main
struct Compare: ParsableCommand {
	@Option(name: .shortAndLong, help: "Path to the older API")
	var old: String = "/Applications/Xcode.app"

	@Option(name: .shortAndLong, help: "Path to the newer API")
	var new: String = "/Applications/Xcode-beta.app"

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
	}
}
