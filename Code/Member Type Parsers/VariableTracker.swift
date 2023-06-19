import Foundation
import SwiftSyntax

class VariableTracker: SyntaxVisitor, MultiTypeParser {
	var value = Member()
	var collection = [Member]()

	required init() {
		self.value.kind = .var
		super.init(viewMode: .sourceAccurate)
	}

	override func visit(_ node: AccessorBlockSyntax) -> SyntaxVisitorContinueKind {
		for accessor in node.accessors {
			if accessor.accessorKind.tokenKind == .keyword(.get) {
				value.accessors.insert(.get)
			}
			if accessor.accessorKind.tokenKind == .keyword(.set) {
				value.accessors.insert(.set)
			}
		}
		return super.visit(node)
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
		value.isWeak = value.isWeak ||  ParseDecl<DeclTracker>(node: node).run(keyword: .weak)
		value.isUnsafe = value.isUnsafe ||  ParseDecl<DeclTracker>(node: node).run(keyword: .unsafe)
		value.isUnowned = value.isUnowned ||  ParseDecl<DeclTracker>(node: node).run(keyword: .unowned)
		return super.visit(node)
	}

	override func visit(_ node: VariableDeclSyntax) -> SyntaxVisitorContinueKind {
		if node.bindingKeyword.tokenKind == .keyword(.let) {
			value.kind = .let
		}

		for pattern in node.bindings {
			var copy = value
			if let name = pattern.pattern.as(IdentifierPatternSyntax.self)?.identifier.text {
				copy.name = name
			}

			if let returnTypeAnnotation = pattern.typeAnnotation {
				copy.returnType = ParseAnyType<DeclTypeNameTracker>(node: returnTypeAnnotation).run()
			}

			if let attributes = pattern.typeAnnotation?.type.as(AttributedTypeSyntax.self)?.attributes {
				for attribute in attributes {
					let name = ParseAnyType<AttributeTracker>(node: attribute).run()
					copy.attributes.insert(name)
				}
			}

			collection.append(copy)
		}
		return super.visit(node)
	}
}
