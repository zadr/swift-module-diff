import Foundation
import SwiftSyntax

class VariableTracker: SyntaxVisitor, AnyTypeCollectionParser {
	var value = Member()
	var collection = [Member]()

	required init() {
		self.value.kind = .var
		super.init(viewMode: .sourceAccurate)
	}

	override func visit(_ node: AccessorBlockSyntax) -> SyntaxVisitorContinueKind {
		switch node.accessors {
		case .accessors:
			value.accessors.insert(.set)
		case .getter:
			value.accessors.insert(.get)
		}
		return super.visit(node)
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
			.weak: .weak,
			.unsafe: .unsafe,
			.unowned: .unowned,
		]

		for (keyword, decorator) in pairs {
			if ParseDecl<DeclTracker>(node: node).run(keyword: keyword) {
				collection = collection.map {
					var copy = $0
					copy.decorators.insert(decorator)
					return copy
				}
			}
		}

		return super.visit(node)
	}

	override func visit(_ node: VariableDeclSyntax) -> SyntaxVisitorContinueKind {
		if node.bindingSpecifier.tokenKind == .keyword(.let) {
			value.kind = .let
		}

		for pattern in node.bindings {
			var copy = value
			if let name = pattern.pattern.as(IdentifierPatternSyntax.self)?.identifier.text {
				copy.name = name
			}

			if let returnTypeAnnotation = pattern.typeAnnotation {
				copy.returnType = ParseAnyType<TypeNameTracker>(node: returnTypeAnnotation).run()
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
