import Foundation
import SwiftParser
import SwiftSyntax

class InoutTracker: SyntaxVisitor, PrimitiveParser {
	typealias Value = Bool

	var value = false

	required init() {
		super.init(viewMode: .sourceAccurate)
	}

	override func visit(_ node: AttributedTypeSyntax) -> SyntaxVisitorContinueKind {
		if node.specifier?.tokenKind == .keyword(.inout) {
			value = true
		}
		return super.visit(node)
	}
}
