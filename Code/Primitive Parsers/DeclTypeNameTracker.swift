import Foundation
import SwiftParser
import SwiftSyntax

class DeclTypeNameTracker: SyntaxVisitor, PrimitiveParser {
	typealias Value = String

	var value = Value()

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
