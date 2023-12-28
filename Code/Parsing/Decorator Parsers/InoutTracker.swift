import Foundation
import SwiftSyntax

class InoutTracker: SyntaxVisitor, AnyTypeParser {
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
