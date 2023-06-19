import Foundation
import SwiftSyntax

class AssociatedTypeTracker: SyntaxVisitor, DataTypeParser {
	static let kind: DataType.Kind = .associatedtype

	var dataType = DataType()

	required init() {
		super.init(viewMode: .sourceAccurate)
	}

	override func visit(_ node: AssociatedtypeDeclSyntax) -> SyntaxVisitorContinueKind {
		dataType.name = node.identifier.text
		return super.visit(node)
	}

	override func visit(_ node: InheritedTypeListSyntax) -> SyntaxVisitorContinueKind {
		dataType.conformances = ParsePrimitive<InheritanceTracker>(node: node).run()
		return super.visit(node)
	}
}
