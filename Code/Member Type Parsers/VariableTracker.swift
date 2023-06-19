import Foundation
import SwiftParser
import SwiftSyntax

class VariableTracker: SyntaxVisitor, MemberParser {
	static let kind: Member.Kind = .var

	var member = Member()

	required init() {
		super.init(viewMode: .sourceAccurate)
	}

	override func visit(_ node: AccessorBlockSyntax) -> SyntaxVisitorContinueKind {
		for accessor in node.accessors {
			if accessor.accessorKind.tokenKind == .keyword(.get) {
				member.accessors.insert(.get)
			}
			if accessor.accessorKind.tokenKind == .keyword(.set) {
				member.accessors.insert(.set)
			}
		}
		return super.visit(node)
	}

	override func visit(_ node: DeclModifierSyntax) -> SyntaxVisitorContinueKind {
		member.isAsync = member.isAsync || ParsePrimitive<AsyncTracker>(node: node).run()
		member.isStatic = member.isStatic || ParsePrimitive<StaticTracker>(node: node).run()
		member.isThrowing = member.isThrowing || ParsePrimitive<ThrowingTracker>(node: node).run()
		member.isOpen = member.isOpen || ParsePrimitive<OpenTracker>(node: node).run()
		member.isFinal = member.isFinal || ParsePrimitive<FinalTracker>(node: node).run()
		return super.visit(node)
	}

	override func visit(_ node: VariableDeclSyntax) -> SyntaxVisitorContinueKind {
		if node.bindingKeyword.tokenKind == .keyword(.let) {
			member.kind = .let
		}

		if let pattern = node.bindings.first {
			member.name = pattern.pattern.description // TODO

			if let returnTypeAnnotation = pattern.typeAnnotation {
				member.returnType = ParsePrimitive<DeclTypeNameTracker>(node: returnTypeAnnotation).run()
			}
		}

		return super.visit(node)
	}

	override func visit(_ node: ReturnClauseSyntax) -> SyntaxVisitorContinueKind {
		member.returnType = ParsePrimitive<DeclTypeNameTracker>(node: node).run()
		return super.visit(node)
	}
}
