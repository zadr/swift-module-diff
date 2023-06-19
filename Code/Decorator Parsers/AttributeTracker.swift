import Foundation
import SwiftSyntax

class AttributeTracker: SyntaxVisitor, PrimitiveParser {
	typealias Value = String

	var value = Value()

	required init() {
		super.init(viewMode: .sourceAccurate)
	}

	override func visit(_ node: AttributeSyntax) -> SyntaxVisitorContinueKind {
		value = ParsePrimitive<DeclTypeNameTracker>(node: node.attributeName).run()
		return super.visit(node)
	}
}
