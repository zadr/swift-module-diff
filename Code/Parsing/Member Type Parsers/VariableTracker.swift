import Foundation
import SwiftSyntax

class VariableTracker: SyntaxVisitor, AnyTypeCollectionParser {
	var value = Member()
	var collection = [Member]()

	required init() {
		value.kind = .var
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
			.nonisolated: .nonisolated
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
				value.attributes += attributes.map { ParseAnyType<AttributeTracker>(node: $0).run() }
			}

			collection.append(copy)
		}
		return super.visit(node)
	}
}
