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
		if attribute.name != "available" {
			value.attributes.insert(attribute)
		}
		return super.visit(node)
	}

	override func visit(_ node: DeclModifierSyntax) -> SyntaxVisitorContinueKind {
		value.isAsync = value.isAsync || ParseDecl<DeclTracker>(node: node).run(keyword: .async)
		value.isStatic = value.isStatic || ParseDecl<DeclTracker>(node: node).run(keyword: .static)
		value.isThrowing = value.isThrowing || ParseDecl<DeclTracker>(node: node).run(keyword: .throws)
		value.isOpen = value.isOpen || ParseDecl<DeclTracker>(node: node).run(keyword: .open)
		value.isFinal = value.isFinal ||  ParseDecl<DeclTracker>(node: node).run(keyword: .final)
		return super.visit(node)
	}

	override func visit(_ node: FunctionDeclSyntax) -> SyntaxVisitorContinueKind {
		if case .binaryOperator(let token) = node.identifier.tokenKind {
			value.name = token
		} else if case .identifier(let token) = node.identifier.tokenKind {
			value.name = token
		} else {
			fatalError("unable to identify func name from decl")
		}
		return super.visit(node)
	}

	override func visit(_ node: FunctionParameterSyntax) -> SyntaxVisitorContinueKind {
		var parameter = Parameter()
		parameter.name = node.firstName.text + (node.secondName != nil ? " " + node.secondName!.text : "")
		parameter.type = ParseAnyType<DeclTypeNameTracker>(node: node.type).run()
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
		value.returnType = ParseAnyType<DeclTypeNameTracker>(node: node).run()
		return super.visit(node)
	}
}

class InitializerTracker: FunctionTracker {
	override func visit(_ node: InitializerDeclSyntax) -> SyntaxVisitorContinueKind {
		if node.optionalMark?.tokenKind == .postfixQuestionMark {
			value.name = "init?"
		} else if node.optionalMark?.tokenKind == .exclamationMark {
			value.name = "init!"
		} else {
			value.name = "init"
		}

		return super.visit(node)
	}
}
