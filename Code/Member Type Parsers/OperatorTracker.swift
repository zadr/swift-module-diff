import Foundation
import SwiftParser
import SwiftSyntax

class OperatorTracker: SyntaxVisitor, MemberParser {
	static let kind: Member.Kind = .operator

	var member = Member()

	required init() {
		super.init(viewMode: .sourceAccurate)
	}

	override func visit(_ node: ReturnClauseSyntax) -> SyntaxVisitorContinueKind {
		member.returnType = ParsePrimitive<DeclTypeNameTracker>(node: node).run()
		return super.visit(node)
	}
}
