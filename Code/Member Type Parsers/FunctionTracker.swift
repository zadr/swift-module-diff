import Foundation
import SwiftParser
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
		let parameter = Parameter(
			name: node.firstName.text + (node.secondName != nil ? " " + node.secondName!.text : ""),
			type: ParsePrimitive<DeclTypeNameTracker>(node: node.type).run(),
			isInout: ParsePrimitive<InoutTracker>(node: node.type).run()
		)
		member.parameters.append(parameter)
		return super.visit(node)
	}

	override func visit(_ node: ReturnClauseSyntax) -> SyntaxVisitorContinueKind {
		member.returnType = ParsePrimitive<DeclTypeNameTracker>(node: node).run()
		return super.visit(node)
	}
}
