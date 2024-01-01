import Foundation
import HTMLEntities

extension ChangedTree {
	static func htmlVisitor(from fromVersion: Version, to toVersion: Version, root: String, extraCSS: String?) -> ChangeVisitor {
		ChangeVisitor(
			didEnd: { tree in
				let title = "Xcode \(fromVersion.name) to Xcode \(toVersion.name) Diff"
				let description = "API changes between Xcode \(fromVersion.name) and Xcode \(toVersion.name)"

				let css = """
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
	padding: 0.5em;
}

summary {
	font-weight: bold;
	padding: 0.5em;
}
"""

				let extraCSSLink: String
				if let extraCSS {
					extraCSSLink = "\n\t<link rel=\"stylesheet\" type=\"text/css\" href=\"\((extraCSS as NSString).lastPathComponent).css\">\n"
				} else {
					extraCSSLink = ""
				}

				var html = """
<!DOCTYPE html lang="en-US">
<head>
	<meta charset="utf-8">
	<title>\(title)</title>
	<meta name="generator" content="swiftmodule-diff">
	<meta property="og:title" content="\(title)">
	<meta property="og:locale" content="en_US">
	<meta name="description" content="\(description)">
	<meta property="og:description" content="\(description)™">
	<meta property="og:url" content="https://example.com/">
	<meta property="og:site_name" content="example.com">
	<meta property="og:type" content="website">
    <link rel="canonical" href="https://example.com/">
	<link rel="stylesheet" type="text/css" href="base.css">\(extraCSSLink)
</head>

<body>

"""

				func append(members: [Change<String>], namedTypes: [ChangedTree.Platform.Architecture.Framework.NamedType], includeTypeName: Bool = false, idStack: [String], depth: Int = 0) {
					let id = idStack.joined(separator: "_")
					let prefix = String(repeating: "\t", count: depth)
					let filteredMembers = members.filter { $0.isNotUnchanged }
					if !filteredMembers.isEmpty {
						html += "\(prefix)\t\t\t\t<details id=\"\(id.replacingOccurrences(of: " ", with: "_").htmlEscape())_members\">\n"
						if includeTypeName {
							html += "\(prefix)\t\t\t\t\t<summary>\(idStack.last!)</summary>\n"
						} else {
							html += "\(prefix)\t\t\t\t\t<summary>Members</summary>\n"
						}

						html += "\(prefix)\t\t\t\t\t<ul>\n"
						for member in filteredMembers.sorted() {
							html += "\(prefix)\t\t\t\t\t\t\t<li class=\"\(member.kind)\">\(member.any.htmlEscape())</li>\n"
						}
						html += "\(prefix)\t\t\t\t\t</ul>\n"
						html += "\(prefix)\t\t\t\t\t</details>\n"
					}

					let filteredNamedTypes = namedTypes.filter { $0.isInteresting }
					if !filteredNamedTypes.isEmpty {
						html += "\(prefix)\t\t\t\t<details id=\"\(id)_types\">\n"
						if includeTypeName {
							html += "\(prefix)\t\t\t\t\t<summary>\(idStack.last!)</summary>\n"
						} else {
							html += "\(prefix)\t\t\t\t\t<summary>Types</summary>\n"
						}
						for type in filteredNamedTypes.sorted() {
							append(members: type.members, namedTypes: type.namedTypes, includeTypeName: true, idStack: idStack + [type.value.any.htmlEscape()], depth: depth + 1)
						}
						html += "\(prefix)\t\t\t\t\t</details>\n"
					}
				}

				for platform in tree.sorted() {
					html += "\t<details id=\"Platform:_\(platform.value.any)\">\n"
					html += "\t<summary>\(platform.value.any)</summary>\n"

					for architecture in platform.architectures.sorted() {
						html += "\t\t<details id=\"Platform_\(platform.value.any)_Architecture_\(architecture.value.any)\">\n"
						html += "\t\t<summary>\(architecture.value.any)</summary>\n"

						for framework in architecture.frameworks.sorted() {
							let dependencies = framework.dependencies.filter { $0.isNotUnchanged }
							let members = framework.members.filter { $0.isNotUnchanged }
							let namedTypes = framework.namedTypes.filter { $0.isInteresting }
							let precedenceGroups = framework.precedenceGroups.filter { $0.isNotUnchanged }

							if dependencies.isEmpty && members.isEmpty && namedTypes.isEmpty && precedenceGroups.isEmpty { continue }

							html += "\t\t\t<details id=\"Platform:_\(platform.value.any)_Architecture:_\(architecture.value.any)_Framework:_\(framework.value.any)\">\n"
							html += "\t\t\t<summary>\(framework.value.emoji) <a href=\"https://developer.apple.com/documentation/\(framework.value.any)\">\(framework.value.any)</a></summary>\n"

							if !dependencies.isEmpty {
								html += "\t\t\t\t<details id=\"Platform:_\(platform.value.any)_Architecture:_\(architecture.value.any)_Framework:_\(framework.value.any)_dependencies\">\n"
								html += "\t\t\t\t\t<summary>Dependencies</summary>\n"
								html += "\t\t\t\t\t\t<ul>\n"
								for dependency in dependencies.sorted() {
									html += "\t\t\t\t\t\t<li class=\"\(dependency.kind)\">\(dependency.any)</li>\n"
								}
								html += "\t\t\t\t\t\t</ul>\n"
								html += "\t\t\t\t</details>\n"
							}

							if !precedenceGroups.isEmpty {
								html += "\t\t\t\t<details id=\"Platform:_\(platform.value.any)_Architecture:_\(architecture.value.any)_Framework:_\(framework.value.any)_precedenceGroups\">\n"
								html += "\t\t\t\t\t<summary>Precedence Groups</summary>\n"
								html += "\t\t\t\t\t\t<ul>\n"
								for precedenceGroup in precedenceGroups.sorted() {
									html += "\t\t\t\t\t\t<li class=\"precedenceGroup\">\(precedenceGroup.any)</li>\n"
								}
								html += "\t\t\t\t\t\t</ul>\n"
								html += "\t\t\t\t</details>\n"
							}

							append(members: framework.members, namedTypes: framework.namedTypes, idStack: ["Platform:_\(platform.value.any)_Architecture:_\(architecture.value.any)_Framework:_\(framework.value.any)"])

							html += "\t\t\t</details>\n"
						}
						html += "\t\t</details>\n"
					}
					html += "\t</details>\n"
				}
				html += "</body>\n"
				let htmlPath = ("\(root)/swiftmodule-diff-\(fromVersion.name)-to-\(toVersion.name).html" as NSString).expandingTildeInPath
				try! html.write(to: URL(fileURLWithPath: htmlPath), atomically: true, encoding: .utf8)

				let cssPath = ("\(root)/base.css" as NSString).expandingTildeInPath
				try! css.write(to: URL(fileURLWithPath: cssPath), atomically: true, encoding: .utf8)

				if let extraCSS {
					let extraCSSPath = ("\(root)/\((extraCSS as NSString).lastPathComponent)" as NSString).expandingTildeInPath
					try! FileManager().copyItem(atPath: extraCSS, toPath: extraCSSPath)
				}
			}
		)
	}
}

extension Change {
	var emoji: String {
		switch self {
		case .removed(_, _):
			""
		case .modified(_, _):
			"〰️"
		case .unchanged(_, _):
			""
		case .added(_, _):
			"➕"
		}
	}
}
