import Foundation

extension Summarizer {
	static func jsonVisitor(from fromVersion: Version, to toVersion: Version, root: String) -> ChangeVisitor {
		return ChangeVisitor(
			didEnd: { tree in
				let interestingTree = tree.notableDifferences()
				let path = ("\(root)/swiftmodule-diff-\(fromVersion.name)-to-\(toVersion.name).json" as NSString).expandingTildeInPath
				let encoder = JSONEncoder()
				encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
				encoder.keyEncodingStrategy = .convertToSnakeCase
				try! encoder.encode(interestingTree).write(to: URL(fileURLWithPath: path))
			}
		)
	}
}
