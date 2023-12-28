import Foundation
import SwiftSyntax

class OperatorTracker: SyntaxVisitor, AnyTypeParser {
	var value = NamedType()

	required init() {
		value.kind = .operator
		super.init(viewMode: .sourceAccurate)
	}

	override func visit(_ node: OperatorDeclSyntax) -> SyntaxVisitorContinueKind {
		value.name = node.name.text

		switch node.fixitySpecifier.tokenKind {
		case .keyword(.infix): value.decorators.insert(.infix)
		case .keyword(.prefix): value.decorators.insert(.prefix)
		case .keyword(.postfix): value.decorators.insert(.postfix)
		default: break
		}

		return super.visit(node)
	}
}
