import Foundation
import SwiftSyntax

class InitializerTracker: FunctionTracker {
	override func visit(_ node: DeclModifierSyntax) -> SyntaxVisitorContinueKind {
		let pairs: [Keyword: Member.Decorator] = [
			.required: .required,
			.convenience: .convenience
		]

		for (keyword, decorator) in pairs {
			if ParseDecl<DeclTracker>(node: node).run(keyword: keyword) {
				value.decorators.insert(decorator)
			}
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
