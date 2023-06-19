import Foundation
import SwiftSyntax

class AssociatedTypeTracker: SyntaxVisitor, AnyTypeParser {
	var value = DataType()

	required init() {
		self.value.kind = .associatedtype
		super.init(viewMode: .sourceAccurate)
	}

	override func visit(_ node: AssociatedtypeDeclSyntax) -> SyntaxVisitorContinueKind {
		value.name = node.identifier.text
		return super.visit(node)
	}

	override func visit(_ node: InheritedTypeListSyntax) -> SyntaxVisitorContinueKind {
		value.conformances = ParseAnyType<InheritanceTracker>(node: node).run()
		return super.visit(node)
	}
}
