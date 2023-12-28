import Foundation
import SwiftSyntax

class InitializerTracker: FunctionTracker {
	override func visit(_ node: InitializerDeclSyntax) -> SyntaxVisitorContinueKind {
		if node.optionalMark?.tokenKind == .postfixQuestionMark {
			value.name = "init?"
		} else if node.optionalMark?.tokenKind == .exclamationMark {
			value.name = "init!"
		} else {
			value.name = "init"
		}

		return super.visit(node)
	}
}
