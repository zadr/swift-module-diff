import Foundation
import SwiftSyntax

class InitializerTracker: FunctionTracker {
	override func visit(_ node: DeclModifierSyntax) -> SyntaxVisitorContinueKind {
		switch node.name.tokenKind {
		case .keyword(.required): value.decorators.insert(.required)
		case .keyword(.convenience): value.decorators.insert(.convenience)
		default: break
		}
		return super.visit(node)
	}

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
