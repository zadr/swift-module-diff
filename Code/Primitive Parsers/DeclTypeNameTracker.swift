import Foundation
import SwiftSyntax

class DeclTypeNameTracker: SyntaxVisitor, AnyTypeParser {
	var value = ""

	required init() {
		super.init(viewMode: .sourceAccurate)
	}

	override func visit(_ node: MemberTypeIdentifierSyntax) -> SyntaxVisitorContinueKind {
		value = value.isEmpty ? node.name.text : node.name.text + "." + value
		return super.visit(node)
	}

	override func visit(_ node: SimpleTypeIdentifierSyntax) -> SyntaxVisitorContinueKind {
		value = value.isEmpty ? node.name.text : node.name.text + "." + value
		return super.visit(node)
	}
}
