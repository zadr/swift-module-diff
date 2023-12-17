import Foundation

extension Summarizer {
	static func jsonVisitor(from fromVersion: Version, to toVersion: Version, root: String) -> ChangeVisitor {
		return ChangeVisitor(
			didEnd: { tree in
				let json = try! JSONEncoder().encode(tree)
				let path = ("\(root)/swiftmodule-diff-\(fromVersion.name)-to-\(toVersion.name).json" as NSString).expandingTildeInPath
				try! json.write(to: URL(fileURLWithPath: path))
			}
		)
	}
}
