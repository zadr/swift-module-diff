import Foundation
import SwiftParser
import SwiftSyntax

class InheritanceTracker: SyntaxVisitor, PrimitiveParser {
	typealias Value = [String]

	var value = Value()

	required init() {
		super.init(viewMode: .sourceAccurate)
	}

	override func visit(_ node: InheritedTypeSyntax) -> SyntaxVisitorContinueKind {
		let name = ParsePrimitive<DeclTypeNameTracker>(node: node).run()
		value.append(name)
		return super.visit(node)
	}
}
