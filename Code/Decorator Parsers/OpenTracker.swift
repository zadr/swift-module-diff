import Foundation
import SwiftParser
import SwiftSyntax

class OpenTracker: SyntaxVisitor, PrimitiveParser {
	typealias Value = Bool

	var value = false

	required init() {
		super.init(viewMode: .sourceAccurate)
	}

	override func visit(_ node: DeclModifierSyntax) -> SyntaxVisitorContinueKind {
		if node.name.tokenKind == .keyword(.open) {
			value = true
		}
		return super.visit(node)
	}
}