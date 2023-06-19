import Foundation
import SwiftSyntax

class TypealiasTracker: SyntaxVisitor, MemberParser {
	static let kind: Member.Kind = .typealias

	var member = Member()

	required init() {
		super.init(viewMode: .sourceAccurate)
	}

	override func visit(_ node: TypealiasDeclSyntax) -> SyntaxVisitorContinueKind {
		member.name = node.identifier.text
		return super.visit(node)
	}

	override func visit(_ node: TypeInitializerClauseSyntax) -> SyntaxVisitorContinueKind {
		member.returnType = ParsePrimitive<DeclTypeNameTracker>(node: node.value).run()
		return super.visit(node)
	}
}
