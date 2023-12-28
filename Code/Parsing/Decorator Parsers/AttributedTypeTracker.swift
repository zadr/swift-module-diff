import Foundation
import SwiftSyntax

class AttributedTypeTracker: DeclTracker {
	override func visit(_ node: AttributedTypeSyntax) -> SyntaxVisitorContinueKind {
		if node.specifier?.tokenKind == .keyword(keyword) {
			value = true
		}
		return super.visit(node)
	}

	override func visit(_ node: SomeOrAnyTypeSyntax) -> SyntaxVisitorContinueKind {
		if node.someOrAnySpecifier.tokenKind == .keyword(keyword) {
			value = true
		}
		return super.visit(node)
	}
}
