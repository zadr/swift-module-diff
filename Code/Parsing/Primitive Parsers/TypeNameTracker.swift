import Foundation
import SwiftSyntax

class TypeNameTracker: SyntaxVisitor, AnyTypeParser {
	var value = ""

	required init() {
		super.init(viewMode: .sourceAccurate)
	}

	override func visit(_ node: TupleTypeSyntax) -> SyntaxVisitorContinueKind {
		let elements = node.elements.map { ParseAnyType<TypeNameTracker>(node: $0).run() }
		var string = elements.joined(separator: ", ")
		if !string.isEmpty {
			string = "(\(string))"
		}
		value += string
		return .skipChildren
	}

	override func visit(_ node: SomeOrAnyTypeSyntax) -> SyntaxVisitorContinueKind {
		switch node.someOrAnySpecifier.tokenKind {
		case .keyword(.some):
			value += "some"
		case .keyword(.any):
			value += "any"
		default: break
		}
		value += " " + ParseAnyType<TypeNameTracker>(node: node.constraint).run()
		return .skipChildren
	}

	override func visit(_ node: MemberTypeSyntax) -> SyntaxVisitorContinueKind {
		value += ParseAnyType<TypeNameTracker>(node: node.baseType).run()
		value += "."
		value += node.name.text
		let generics = node.genericArgumentClause?.arguments.map { ParseAnyType<TypeNameTracker>(node: $0).run() } ?? []
		var string = generics.joined(separator: ", ")
		if !string.isEmpty {
			string = "<\(string)>"
		}
		value += string
		return .skipChildren
	}

	override func visit(_ node: IdentifierTypeSyntax) -> SyntaxVisitorContinueKind {
		value += node.name.text
		let generics = node.genericArgumentClause?.arguments.map { ParseAnyType<TypeNameTracker>(node: $0).run() } ?? []
		var string = generics.joined(separator: ", ")
		if !string.isEmpty {
			string = "<\(string)>"
		}
		value += string
		return .skipChildren
	}

	override func visit(_ node: OptionalTypeSyntax) -> SyntaxVisitorContinueKind {
		value += ParseAnyType<TypeNameTracker>(node: node.wrappedType).run()
		value += "?"
		return .skipChildren
	}

	override func visit(_ node: DictionaryTypeSyntax) -> SyntaxVisitorContinueKind {
		value += "["
		value += ParseAnyType<TypeNameTracker>(node: node.key).run()
		value += ": "
		value += ParseAnyType<TypeNameTracker>(node: node.value).run()
		value += "]"
		return .skipChildren
	}

	override func visit(_ node: ArrayTypeSyntax) -> SyntaxVisitorContinueKind {
		value += "["
		value += ParseAnyType<TypeNameTracker>(node: node.element).run()
		value += "]"
		return .skipChildren
	}

	override func visit(_ node: FunctionTypeSyntax) -> SyntaxVisitorContinueKind {
		value += "("
		value += node.parameters.map { ParseAnyType<TypeNameTracker>(node: $0).run() }.joined(separator: ", ")
		value += ")"
		value += " -> " + ParseAnyType<TypeNameTracker>(node: node.returnClause.type).run()

		return .skipChildren
	}
}
