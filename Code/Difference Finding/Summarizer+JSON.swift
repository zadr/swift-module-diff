import Foundation

extension Summarizer {
	static func jsonVisitor(from fromVersion: Version, to toVersion: Version, root: String) -> ChangeVisitor {
		return ChangeVisitor(
			didEnd: { tree in
				var interestingTree = [Summarizer.Platform]()

				func append(members: [Change<String>], nested namedTypes: [Summarizer.Platform.Architecture.Framework.NamedType], to parent: inout Nested) {
					let filteredMembers = members.filter { $0.isNotUnchanged }
					if !filteredMembers.isEmpty {
						parent.members.append(contentsOf: filteredMembers.sorted())
					}

					let filteredNamedTypes = namedTypes.filter { $0.isInteresting }
					for type in filteredNamedTypes.sorted() {
						var nested: Nested = Summarizer.Platform.Architecture.Framework.NamedType(value: type.value)
						append(members: type.members, nested: type.namedTypes, to: &nested)
						parent.namedTypes.append(type)
					}
				}

				for platform in tree.sorted() {
					interestingTree.append(.init(value: platform.value))

					for architecture in platform.architectures.sorted() {
						interestingTree.last!.architectures.append(.init(value: architecture.value))

						for framework in architecture.frameworks.sorted() {
							let dependencies = framework.dependencies.filter { $0.isNotUnchanged }
							let members = framework.members.filter { $0.isNotUnchanged }
							let namedTypes = framework.namedTypes.filter { $0.isInteresting }

							if dependencies.isEmpty && members.isEmpty && namedTypes.isEmpty {
								continue
							}

							let frameworkAsFramework = Summarizer.Platform.Architecture.Framework(value: framework.value)
							if !dependencies.isEmpty {
								frameworkAsFramework.dependencies += dependencies
							}

							var frameworkAsNested: Nested = frameworkAsFramework

							append(members: members, nested: namedTypes, to: &frameworkAsNested)
							interestingTree.last!.architectures.last!.frameworks.append(frameworkAsFramework)
							continue
						}
					}
				}

				let path = ("\(root)/swiftmodule-diff-\(fromVersion.name)-to-\(toVersion.name).json" as NSString).expandingTildeInPath
				let encoder = JSONEncoder()
				encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
				encoder.keyEncodingStrategy = .convertToSnakeCase
				try! encoder.encode(interestingTree).write(to: URL(fileURLWithPath: path))
			}
		)
	}
}
