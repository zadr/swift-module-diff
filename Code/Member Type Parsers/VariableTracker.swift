import Foundation
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

	override func visit(_ node: AttributeSyntax) -> SyntaxVisitorContinueKind {
		   let attribute = ParsePrimitive<AttributeTracker>(node: node).run()
		   if attribute.name != "available" {
			   member.attributes.insert(attribute)
		   }
		   return super.visit(node)
	   }

	override func visit(_ node: DeclModifierSyntax) -> SyntaxVisitorContinueKind {
		member.isAsync = member.isAsync || ParseDecl<DeclTracker>(node: node).run(keyword: .async)
		member.isStatic = member.isStatic || ParseDecl<DeclTracker>(node: node).run(keyword: .static)
		member.isThrowing = member.isThrowing || ParseDecl<DeclTracker>(node: node).run(keyword: .throws)
		member.isOpen = member.isOpen || ParseDecl<DeclTracker>(node: node).run(keyword: .open)
		member.isFinal = member.isFinal ||  ParseDecl<DeclTracker>(node: node).run(keyword: .final)
		return super.visit(node)
	}

	override func visit(_ node: VariableDeclSyntax) -> SyntaxVisitorContinueKind {
		if node.bindingKeyword.tokenKind == .keyword(.let) {
			member.kind = .let
		}

		if let pattern = node.bindings.first {
			if let name = pattern.pattern.as(IdentifierPatternSyntax.self)?.identifier.text {
				member.name = name
			}

			if let returnTypeAnnotation = pattern.typeAnnotation {
				member.returnType = ParsePrimitive<DeclTypeNameTracker>(node: returnTypeAnnotation).run()
			}

			if let attributes = pattern.typeAnnotation?.type.as(AttributedTypeSyntax.self)?.attributes {
				for attribute in attributes {
					let name = ParsePrimitive<AttributeTracker>(node: attribute).run()
					member.attributes.insert(name)
				}
			}
		}
		return super.visit(node)
	}

	override func visit(_ node: ReturnClauseSyntax) -> SyntaxVisitorContinueKind {
		member.returnType = ParsePrimitive<DeclTypeNameTracker>(node: node).run()
		return super.visit(node)
	}
}
