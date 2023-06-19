import Foundation

print(Date())
var frameworks = Set<Framework>()

let paths = [
	"/Applications/Xcode-beta.app",
	"/Applications/Xcode.app"
]
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
				print(framework)
			}
		}
	}
}
print(Date())
