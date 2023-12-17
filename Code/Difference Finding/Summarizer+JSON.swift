import Foundation

extension Summarizer {
	static func jsonVisitor(from fromVersion: Version, to toVersion: Version, root: String) -> ChangeVisitor {
		var tree: [
			String: [ // platform
				String: [ // architecture
					String: [ // framework
						String: [String] // dependency | type | member
					]
				]
			]
		] = [:]
		var keyPathStack = [String]()
		return ChangeVisitor(
			didEnd: {
				let json = try! JSONEncoder().encode(tree)
				let path = ("\(root)/swiftmodule-diff-\(fromVersion.name)-to-\(toVersion.name).json" as NSString).expandingTildeInPath
				try! json.write(to: URL(fileURLWithPath: path))
			},
			willVisitPlatform: { change in
				tree[change.any.name] = .init()
				keyPathStack.append(change.any.name)
			},
			didVisitPlatform: { change in
				keyPathStack.removeLast()
			},
			willVisitArchitecture: { change in
				tree[keyPathStack[0]]![change.any.name] = .init()
				keyPathStack.append(change.any.name)
			},
			didVisitArchitecture: { change in
				keyPathStack.removeLast()
			},
			willVisitFramework: { change in
				tree[keyPathStack[0]]![keyPathStack[1]]![change.any.name] = .init()
				keyPathStack.append(change.any.name)
			},
			didVisitFramework: { change in
				keyPathStack.removeLast()
			},
			willVisitDependency: { change in
				var dependencies = tree[keyPathStack[0]]![keyPathStack[1]]![keyPathStack[2]]!["dependencies"] ?? [String]()
				dependencies.append(change.any.developerFacingValue)
				tree[keyPathStack[0]]![keyPathStack[1]]![keyPathStack[2]]!["dependencies"] = dependencies
			},
			willVisitNamedType: { change in
				var dependencies = tree[keyPathStack[0]]![keyPathStack[1]]![keyPathStack[2]]!["type"] ?? [String]()
				dependencies.append(change.any.developerFacingValue)
				tree[keyPathStack[0]]![keyPathStack[1]]![keyPathStack[2]]!["type"] = dependencies
			},
			willVisitMember: { change in
				var dependencies = tree[keyPathStack[0]]![keyPathStack[1]]![keyPathStack[2]]!["member"] ?? [String]()
				dependencies.append(change.any.developerFacingValue)
				tree[keyPathStack[0]]![keyPathStack[1]]![keyPathStack[2]]!["member"] = dependencies
			}
		)
	}
}
