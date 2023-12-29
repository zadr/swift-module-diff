import Foundation
import SwiftSyntax

class VariableTracker: SyntaxVisitor, AnyTypeCollectionParser {
	var value = Member()
	var collection = [Member]()

	required init() {
		value.kind = .var
		super.init(viewMode: .sourceAccurate)
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
			.nonisolated: .nonisolated,
			.optional: .optional,
			.lazy: .lazy,
			.dynamic: .dynamic
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
				copy.attributes += attributes.map { ParseAnyType<AttributeTracker>(node: $0).run() }
			}

			if case .accessors(let accessors) = pattern.accessorBlock?.accessors {
				for accessor in accessors {
					switch accessor.modifier?.name.tokenKind ?? .keyword(.none) {
					case .keyword(.nonmutating):
						copy.accessors.append(.nonmutating)
					case .keyword(.mutating):
						copy.accessors.append(.mutating)
					default: break;
					}

					switch accessor.accessorSpecifier.tokenKind {
					case .keyword(.set):
						copy.accessors.append(.set)
					case .keyword(.get):
						copy.accessors.append(.get)

						if case .keyword(.async) = accessor.effectSpecifiers?.asyncSpecifier?.tokenKind {
							copy.accessors.append(.async)
						}
						if case .keyword(.throws) = accessor.effectSpecifiers?.throwsSpecifier?.tokenKind {
							copy.accessors.append(.throws)
						}
					default: break
					}
				}
			}

			collection.append(copy)
		}
		return super.visit(node)
	}
}
