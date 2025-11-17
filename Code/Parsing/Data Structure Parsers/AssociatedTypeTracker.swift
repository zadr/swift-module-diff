import Foundation
import SwiftSyntax

class AssociatedTypeTracker: SyntaxVisitor, AnyTypeParser {
	var value = NamedType()

	required init() {
		value.kind = .associatedtype
		super.init(viewMode: .sourceAccurate)
	}

	override func visit(_ node: AssociatedTypeDeclSyntax) -> SyntaxVisitorContinueKind {
		value.name = node.name.text
		return super.visit(node)
	}

	override func visit(_ node: InheritedTypeListSyntax) -> SyntaxVisitorContinueKind {
		value.conformances = ParseAnyType<InheritanceTracker>(node: node).run().sorted()
		return super.visit(node)
	}
}
