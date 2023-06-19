import Foundation
import SwiftSyntax

class StaticTracker: SyntaxVisitor, PrimitiveParser {
	typealias Value = Bool

	var value = false

	required init() {
		super.init(viewMode: .sourceAccurate)
	}

	override func visit(_ node: DeclModifierSyntax) -> SyntaxVisitorContinueKind {
		if node.name.tokenKind == .keyword(.static) {
			value = true
		}
		return super.visit(node)
	}
}
