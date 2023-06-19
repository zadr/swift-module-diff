import Foundation
import SwiftSyntax

class OperatorTracker: SyntaxVisitor, AnyTypeParser {
	var value = Member()

	required init() {
		self.value.kind = .operator
		super.init(viewMode: .sourceAccurate)
	}

	override func visit(_ node: ReturnClauseSyntax) -> SyntaxVisitorContinueKind {
		value.returnType = ParseAnyType<DeclTypeNameTracker>(node: node).run()
		return super.visit(node)
	}
}
