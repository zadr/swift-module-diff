import Foundation
import SwiftSyntax

class TypeNameTracker: SyntaxVisitor, AnyTypeParser {
	var value = ""
	var isInTuple = false
	
	required init() {
		super.init(viewMode: .sourceAccurate)
	}
	
	override func visit(_ node: TupleTypeElementSyntax) -> SyntaxVisitorContinueKind {
		isInTuple = true
		return super.visit(node)
	}
	
	override func visit(_ node: MemberTypeIdentifierSyntax) -> SyntaxVisitorContinueKind {
		value = value.isEmpty ? node.name.text : node.name.text + joiner + value
		return super.visit(node)
	}
	
	override func visit(_ node: SimpleTypeIdentifierSyntax) -> SyntaxVisitorContinueKind {
		value = value.isEmpty ? node.name.text : node.name.text + joiner + value
		return super.visit(node)
	}
}

extension TypeNameTracker {
	var joiner: String {
		isInTuple ? ", " : "."
	}
}
