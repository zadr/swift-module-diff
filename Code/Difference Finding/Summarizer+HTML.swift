import Foundation

extension Summarizer {
	static func htmlVisitor(from fromVersion: Version, to toVersion: Version, root: String) -> ChangeVisitor {
		return ChangeVisitor(
			didEnd: { tree in
				let title = "Xcode \(fromVersion.name) to Xcode \(toVersion.name) Diff"
				let description = "API changes between Xcode \(fromVersion.name) and Xcode \(toVersion.name)"

				var html = """
<!DOCTYPE html>
<head>
	<meta charset="utf-8">
	<title>\(title)</title>
	<meta name="generator" content="swiftmodule-diff">
	<meta property="og:title" content="\(title)">
	<meta property="og:locale" content="en_US">
	<meta name="description" content="\(description)">
	<meta property="og:description" content="\(description)™">
	<link rel="canonical" href="https://example.com/">
	<meta property="og:url" content="https://example.com/">
	<meta property="og:site_name" content="example.com">
	<meta property="og:type" content="website">
	<style>
		a {
			color: black;
		}

		ul {
			list-style: none;
		}

		li.added:before {
			content: "➕";
			padding-right: 5px;
		}

		li.modified:before {
			content: "〰️";
			padding-right: 5px;
		}

		li.removed:before {
			content: "➖";
			padding-right: 5px;
		}

		details {
			border: 1px solid #aaa;
			border-radius: 4px;
			padding: 0.5em 0.5em 0;
		}

		summary {
			font-weight: bold;
			padding: 0.5em;
		}

		details[open] {
			padding: 0.5em;
		}

		details[open] summary {
			border-bottom: 1px solid #aaa;
			margin-bottom: 0.5em;
		}
	</style>
</head>

<html lang="en-US">
"""

				func append(members: [Change<String>], namedTypes: [Summarizer.Platform.Architecture.Framework.NamedType], includeTypeName: Bool = false, idStack: [String], depth: Int = 0) {
					let id = idStack.joined(separator: " ")
					let prefix = String(repeating: "\t", count: depth)
					let filteredMembers = members.filter { $0.isNotUnchanged }
					if !filteredMembers.isEmpty {
						html += "\(prefix)\t\t\t\t<details id=\"\(id) members\">\n"
						if includeTypeName {
							html += "\(prefix)\t\t\t\t\t<summary>\(idStack.last!)</summary>\n"
						} else {
							html += "\(prefix)\t\t\t\t\t<summary>Members</summary>\n"
						}

						html += "\(prefix)\t\t\t\t\t<ul>\n"
						for member in filteredMembers.sorted() {
							html += "\(prefix)\t\t\t\t\t\t\t<li class=\"\(member.kind)\">\(member.any)</li>\n"
						}
						html += "\(prefix)\t\t\t\t\t</ul>\n"
						html += "\(prefix)\t\t\t\t\t</details>\n"
					}

					let filteredNamedTypes = namedTypes.filter { $0.isInteresting }
					if !filteredNamedTypes.isEmpty {
						html += "\(prefix)\t\t\t\t<details id=\"\(id) types\">\n"
						if includeTypeName {
							html += "\(prefix)\t\t\t\t\t<summary>\(idStack.last!)</summary>\n"
						} else {
							html += "\(prefix)\t\t\t\t\t<summary>Types</summary>\n"
						}
						for type in filteredNamedTypes.sorted() {
							append(members: type.members, namedTypes: type.namedTypes, includeTypeName: true, idStack: idStack + [type.value.any], depth: depth + 1)
						}
						html += "\(prefix)\t\t\t\t\t</details>\n"
					}
				}

				for platform in tree.sorted() {
					html += "\t<details id=\"Platform: \(platform.value.any)\">\n"
					html += "\t<summary>\(platform.value.any)</summary>\n"

					for architecture in platform.architectures.sorted() {
						html += "\t\t<details id=\"Platform: \(platform.value.any) Architecture: \(architecture.value.any)\">\n"
						html += "\t\t<summary>\(architecture.value.any)</summary>\n"

						for framework in architecture.frameworks.sorted() {
							let dependencies = framework.dependencies.filter { $0.isNotUnchanged }
							let members = framework.members.filter { $0.isNotUnchanged }
							let namedTypes = framework.namedTypes.filter { $0.isInteresting }

							if dependencies.isEmpty && members.isEmpty && namedTypes.isEmpty { continue }

							html += "\t\t\t<details id=\"Platform: \(platform.value.any) Architecture: \(architecture.value.any) Framework: \(framework.value.any)\">\n"
							html += "\t\t\t<summary>\(framework.value.emoji) <a href=\"https://developer.apple.com/documentation/\(framework.value.any)\">\(framework.value.any)</a></summary>\n"

							if !dependencies.isEmpty {
								html += "\t\t\t\t<details id=\"Platform: \(platform.value.any) Architecture: \(architecture.value.any) Framework: \(framework.value.any) dependencies\">\n"
								html += "\t\t\t\t\t<summary>Dependencies</summary>\n"
								html += "\t\t\t\t\t\t<ul>\n"
								for dependency in dependencies.sorted() {
									html += "\t\t\t\t\t\t\t<li class=\"\(dependency.kind)\">\(dependency.any)</li>\n"
								}
								html += "\t\t\t\t\t\t</ul>\n"
								html += "\t\t\t\t\t</details>\n"
							}

							append(members: framework.members, namedTypes: framework.namedTypes, idStack: ["Platform: \(platform.value.any) Architecture: \(architecture.value.any) Framework: \(framework.value.any)"])

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
