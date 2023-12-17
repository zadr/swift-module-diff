import Foundation
import SwiftSyntax

class TypeNameTracker: SyntaxVisitor, AnyTypeParser {
	var value = ""
	var isInTuple = false
	var isInFunction = false
	var isInReturnType = false
	var indexBeforeReturnStatementBegan: String.Index? = nil

	required init() {
		super.init(viewMode: .sourceAccurate)
	}

	override func visit(_ node: TupleTypeSyntax) -> SyntaxVisitorContinueKind {
		value += " ("
		return super.visit(node)
	}

	override func visitPost(_ node: TupleTypeSyntax) {
		value += ")"
		return super.visitPost(node)
	}

	override func visit(_ node: TupleTypeElementListSyntax) -> SyntaxVisitorContinueKind {
		if isInTuple {
			value = value + ParseAnyType<TypeNameTracker>(node: node).run()
			return .skipChildren
		} else {
			isInTuple = true
		}
		return super.visit(node)
	}

	override func visit(_ node: FunctionTypeSyntax) -> SyntaxVisitorContinueKind {
		isInFunction = true
		value = value.isEmpty ? "(" : value + ", ("
		return super.visit(node)
	}

	override func visitPost(_ node: FunctionTypeSyntax) {
		isInFunction = false

		if let indexBeforeReturnStatementBegan {
			value.insert(")", at: indexBeforeReturnStatementBegan)
		}
		return super.visitPost(node)
	}

	override func visit(_ node: AttributeSyntax) -> SyntaxVisitorContinueKind {
		value += " " + node.atSign.text
		return super.visit(node)
	}

	override func visit(_ node: MemberTypeSyntax) -> SyntaxVisitorContinueKind {
		if value.isEmpty || value.hasSuffix(" -> ") || value.hasSuffix("(") {
			value += node.name.text
		} else {
			if !isInTuple {
				value = (node.name.text + joiner + value)
			} else {
				value += (joiner + node.name.text)
			}
		}
		return super.visit(node)
	}
	
	override func visit(_ node: IdentifierTypeSyntax) -> SyntaxVisitorContinueKind {
		if value.isEmpty || value.hasSuffix(" -> ") || value.hasSuffix("(") {
			value += node.name.text
		} else {
			if !isInTuple {
				value = (node.name.text + joiner + value)
			} else {
				value += (joiner + node.name.text)
			}
		}
		return super.visit(node)
	}

	override func visit(_ node: ReturnClauseSyntax) -> SyntaxVisitorContinueKind {
		if isInFunction {
			indexBeforeReturnStatementBegan = value.endIndex
			value = value + " -> "
		}
		isInReturnType = true
		return super.visit(node)
	}
}

extension TypeNameTracker {
	var joiner: String {
		if value.last == "@" { return "" }
		return isInTuple ? ", " : "."
	}
}
