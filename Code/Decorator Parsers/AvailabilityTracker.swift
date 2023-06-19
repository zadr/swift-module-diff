import Foundation
import SwiftSyntax

class AvailabilityTracker: SyntaxVisitor, AnyTypeParser {
	var value = [Availability]()

	required init() {
		super.init(viewMode: .sourceAccurate)
	}

	override func visit(_ node: AvailabilityVersionRestrictionSyntax) -> SyntaxVisitorContinueKind {
		if let major = node.version?.major, let remainder = node.version?.components, !remainder.isEmpty {
			let versionString = "\(major)." + remainder.map { $0.number.text }.joined(separator: ".")
			value.append(.platform(name: node.platform.text, version: versionString))
		} else if let major = node.version?.major {
			let versionString = "\(major)"
			value.append(.platform(name: node.platform.text, version: versionString))
		} else {
			value.append(.platform(name: node.platform.text, version: "*"))
		}

		return super.visit(node)
	}
}
