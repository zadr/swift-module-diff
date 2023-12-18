import Foundation
import SwiftSyntax

class FunctionTracker: SyntaxVisitor, AnyTypeParser {
	var value = Member()

	required init() {
		self.value.kind = .func
		super.init(viewMode: .sourceAccurate)
	}

	override func visit(_ node: AttributeSyntax) -> SyntaxVisitorContinueKind {
		let attribute = ParseAnyType<AttributeTracker>(node: node).run()
		value.attributes.insert(attribute)
		return super.visit(node)
	}

	override func visit(_ node: DeclModifierSyntax) -> SyntaxVisitorContinueKind {
		let pairs: [Keyword: Member.Decorator] = [
			.async: .async,
			.static: .static,
			.throws: .throwing,
			.open: .open,
			.final: .final,
		]

		for (keyword, decorator) in pairs {
			if ParseDecl<DeclTracker>(node: node).run(keyword: keyword) {
				value.decorators.insert(decorator)
			}
		}
		return super.visit(node)
	}

	override func visit(_ node: FunctionDeclSyntax) -> SyntaxVisitorContinueKind {
		if case .binaryOperator(let token) = node.name.tokenKind {
			value.name = token
		} else if case .identifier(let token) = node.name.tokenKind {
			value.name = token
		} else {
			fatalError("unable to identify func name from decl")
		}
		return super.visit(node)
	}

	override func visit(_ node: FunctionParameterSyntax) -> SyntaxVisitorContinueKind {
		var parameter = Parameter()
		parameter.name = node.firstName.text + (node.secondName != nil ? " " + node.secondName!.text : "")
		parameter.type = ParseAnyType<TypeNameTracker>(node: node.type).run()
		parameter.isInout = ParseAnyType<InoutTracker>(node: node.type).run()

		if let attributes = node.type.as(AttributedTypeSyntax.self)?.attributes {
			for attribute in attributes {
				let name = ParseAnyType<AttributeTracker>(node: attribute).run()
				parameter.attributes.insert(name)
			}
		}

		value.parameters.append(parameter)
		return super.visit(node)
	}

	override func visit(_ node: ReturnClauseSyntax) -> SyntaxVisitorContinueKind {
		value.returnType = ParseAnyType<TypeNameTracker>(node: node).run()
		return super.visit(node)
	}
}
