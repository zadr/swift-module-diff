import Foundation

extension Summarizer {
	static func jsonVisitor(from fromVersion: Version, to toVersion: Version, root: String) -> ChangeVisitor {
		return ChangeVisitor(
			didEnd: { tree in
				let title = "Xcode \(fromVersion.name) to Xcode \(toVersion.name) Diff"
				let description = "API changes between Xcode \(fromVersion.name) and Xcode \(toVersion.name)"

				var json = """
{
\t"title": "\(title)",
\t"description": "\(description)",

"""

				func append(members: [Change<String>], namedTypes: [Summarizer.Tree.Platform.Architecture.Framework.NamedType], depth: Int = 0) {
					let prefix = String(repeating: "\t", count: depth)
					let filteredMembers = members.filter { !$0.isUnchanged }
					if !filteredMembers.isEmpty {
						json += """
\(prefix)\t\t\t\t\t{
\(prefix)\t\t\t\t\t\t"members": [

"""
						for member in filteredMembers.sorted() {
							json += """
\(prefix)\t\t\t\t\t\t\t{
\(prefix)\t\t\t\t\t\t\t\t"change": "\(member.kind)",
\(prefix)\t\t\t\t\t\t\t\t"value": "\(member.any)"
\(prefix)\t\t\t\t\t\t\t},

"""
						}
						json += "\(prefix)\t\t\t\t\t\t]\n"
					}

					let filteredNamedTypes = namedTypes.filter { $0.isInteresting }
					if !filteredNamedTypes.isEmpty {
						json += """
\(prefix)\t\t\t\t\t"nested_types": [

"""
						for type in filteredNamedTypes.sorted() {
							append(members: type.members, namedTypes: type.namedTypes, depth: depth + 1)
						}
						json += "\(prefix)\t\t\t\t\t]\n"
					}
					json += "\(prefix)\t\t\t\t\t},\n"
				}

				for platform in tree.sorted() {
					json += """
\t"\(platform.value.any)": {

"""
					for architecture in platform.architectures.sorted() {
						json += """
\t\t"\(architecture.value.any)": {

"""

						for framework in architecture.frameworks.sorted() {
							let dependencies = framework.dependencies.filter { !$0.isUnchanged }
							let members = framework.members.filter { !$0.isUnchanged }
							let namedTypes = framework.namedTypes.filter { $0.isInteresting }

							if dependencies.isEmpty && members.isEmpty && namedTypes.isEmpty { continue }

							json += """
\t\t\t"\(framework.value.any)": {

"""

							if !dependencies.isEmpty {
								json += """
\t\t\t\t"dependencies": [

"""
								for dependency in dependencies.sorted() {
									json += """
\t\t\t\t\t{
\t\t\t\t\t\t"change": "\(dependency.kind)",
\t\t\t\t\t\t"value": "\(dependency.any)"
\t\t\t\t\t},

"""
								}
								json += "\t\t\t\t]\n"
							}

							append(members: framework.members, namedTypes: framework.namedTypes)

							json += "\t\t\t},\n"
						}
						json += "\t\t},\n"
					}
					json += "\t},\n"
				}
				json += "}\n"
				let path = ("\(root)/swiftmodule-diff-\(fromVersion.name)-to-\(toVersion.name).json" as NSString).expandingTildeInPath
				try! json.write(to: URL(fileURLWithPath: path), atomically: true, encoding: .utf8)
			}
		)
	}
}
