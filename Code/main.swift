import Foundation

print(Date())
let modules = SwiftmoduleFinder(app: "/Applications/Xcode-beta.app").run()
for (platform, architectureToModules) in modules {
	print(platform)

	for (architecture, moduleList) in architectureToModules {
		print(architecture)

		for module in moduleList {
			print(module.absoluteString)
		
			let path = module.absoluteString.replacingOccurrences(of: "file://", with: "")

			let framework = ParseSwiftmodule(path: path).run()
			print(framework)
			exit(EXIT_SUCCESS)
		}
	}
}
print(Date())
