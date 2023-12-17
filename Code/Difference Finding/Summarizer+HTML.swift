import Foundation

extension Summarizer {
	static func htmlVisitor(from fromVersion: Version, to toVersion: Version, root: String) -> ChangeVisitor {
		return ChangeVisitor(
			didEnd: { tree in
				let title = "swiftmodule \(fromVersion.name) to Xcode \(toVersion.name) Diff"
				let description = "API changes between Xcode \(fromVersion.name) and Xcode \(toVersion.name)"

				var html = """
<!DOCTYPE html>
<head>
	<meta charset="utf-8">
	<title>\(title)</title>
	<meta name="generator" content="swiftmodule-diff">
	<meta property="og:title" content="\(title)">
	<meta property="og:locale" content="en_US">
	<meta name="description" content"\(description)"=>
	<meta property="og:description" content="\(description)™">
	<link rel="canonical" href="https://example.com/">
	<meta property="og:url" content="https://example.com/">
	<meta property="og:site_name" content="example.com">
	<meta property="og:type" content="website">
</head>

<html lang="en-US">
"""
				for platform in tree.sorted() {
					html += "\t<details id=\"Platform: \(platform.value)\">\n"
					html += "\t<summary>Platform: \(platform.value)</summary>\n"

					for architecture in platform.architectures.sorted() {
						html += "\t\t<details id=\"Platform: \(platform.value) Architecture: \(architecture.value)\">\n"
						html += "\t\t<summary>Architecture: \(architecture.value)</summary>\n"

						for framework in architecture.frameworks.sorted() {
							html += "\t\t\t<details id=\"Platform: \(platform.value) Architecture: \(architecture.value) Framework: \(framework.value)\">\n"
							html += "\t\t\t<summary>Framework: \(framework.value)</summary>\n"

							let dependencies = framework.dependencies
							if !dependencies.isEmpty {
								html += "\t\t\t\t<details id=\"Platform: \(platform.value) Architecture: \(architecture.value) Framework: \(framework.value) dependencies\">\n"
								html += "\t\t\t\t\t<summary>dependencies</summary>\n"
								html += "\t\t\t\t\t\t<table>\n"
								for dependency in dependencies.sorted() {
									html += "\t\t\t\t\t\t\t<tr><td>\(dependency)</td>></tr>\n"
								}
								html += "\t\t\t\t\t\t</table>\n"
								html += "\t\t\t\t\t</details>\n"
							}

							// TODO: nest members + types recursively
							let members = framework.members
							if !members.isEmpty {
								html += "\t\t\t\t<details id=\"Platform: \(platform.value) Architecture: \(architecture.value) Framework: \(framework.value) members\">\n"
								html += "\t\t\t\t\t<summary>members</summary>\n"
								html += "\t\t\t\t\t\t<table>\n"
								for member in members.sorted() {
									html += "\t\t\t\t\t\t\t<tr><td>\(member)</td>></tr>\n"
								}
								html += "\t\t\t\t\t\t</table>\n"
								html += "\t\t\t\t\t</details>\n"
							}

							let types = framework.namedTypes
							if !types.isEmpty {
								html += "\t\t\t\t<details id=\"Platform: \(platform.value) Architecture: \(architecture.value) Framework: \(framework.value) types\">\n"
								html += "\t\t\t\t\t<summary>types</summary>\n"
								html += "\t\t\t\t\t\t<table>\n"
								for type in types.sorted() {
									html += "\t\t\t\t\t\t\t<tr><td>\(type.value)</td></tr>\n"
								}
								html += "\t\t\t\t\t\t</table>\n"
								html += "\t\t\t\t\t</details>\n"
							}
							html += "\t\t\t</details>\n"
						}
						html += "\t\t</details>\n"
					}
					html += "\t</details>\n"
				}
				html += "</html>\n"
				let path = ("\(root)/swiftmodule-diff-\(fromVersion.name)-to-\(toVersion.name).html" as NSString).expandingTildeInPath
				try! html.write(to: URL(fileURLWithPath: path), atomically: true, encoding: .utf8)
			}
		)
	}
}
