import Foundation
import SwiftSyntax

class FunctionTracker: SyntaxVisitor, MemberParser {
	static let kind: Member.Kind = .func

	var member = Member()

	required init() {
		super.init(viewMode: .sourceAccurate)
	}

	override func visit(_ node: DeclModifierSyntax) -> SyntaxVisitorContinueKind {
		member.isAsync = member.isAsync || ParsePrimitive<AsyncTracker>(node: node).run()
		member.isStatic = member.isStatic || ParsePrimitive<StaticTracker>(node: node).run()
		member.isThrowing = member.isThrowing || ParsePrimitive<ThrowingTracker>(node: node).run()
		member.isOpen = member.isOpen || ParsePrimitive<OpenTracker>(node: node).run()
		member.isFinal = member.isFinal || ParsePrimitive<FinalTracker>(node: node).run()
		return super.visit(node)
	}

	override func visit(_ node: FunctionDeclSyntax) -> SyntaxVisitorContinueKind {
		if case .binaryOperator(let token) = node.identifier.tokenKind {
			member.name = token
		} else if case .identifier(let token) = node.identifier.tokenKind {
			member.name = token
		} else {
			fatalError("unable to identify func name from decl")
		}
		return super.visit(node)
	}

	override func visit(_ node: FunctionParameterSyntax) -> SyntaxVisitorContinueKind {
		var parameter = Parameter()
		parameter.name = node.firstName.text + (node.secondName != nil ? " " + node.secondName!.text : "")
		parameter.type = ParsePrimitive<DeclTypeNameTracker>(node: node.type).run()
		parameter.isInout = ParsePrimitive<InoutTracker>(node: node.type).run()

		if let attributes = node.type.as(AttributedTypeSyntax.self)?.attributes {
			for attribute in attributes {
				let name = ParsePrimitive<AttributeTracker>(node: attribute).run()
				parameter.attributes.insert(name)
			}
		}

		member.parameters.append(parameter)
		return super.visit(node)
	}

	override func visit(_ node: ReturnClauseSyntax) -> SyntaxVisitorContinueKind {
		member.returnType = ParsePrimitive<DeclTypeNameTracker>(node: node).run()
		return super.visit(node)
	}
}
