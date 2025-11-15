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
		var decorator: Member.Decorator?

		switch node.name.tokenKind {
		case .keyword(.static): decorator = .static
		case .keyword(.open): decorator = .open
		case .keyword(.package): decorator = .package
		case .keyword(.final): decorator = .final
		case .keyword(.weak): decorator = .weak
		case .keyword(.nonisolated): decorator = .nonisolated
		case .keyword(.optional): decorator = .optional
		case .keyword(.lazy): decorator = .lazy
		case .keyword(.dynamic): decorator = .dynamic
		case .keyword(.unowned):
			// Check for unowned(safe) vs unowned(unsafe) vs unowned
			if let detail = node.detail?.detail.tokenKind {
				if case .identifier("unsafe") = detail {
					decorator = .unsafe
				} else if case .identifier("safe") = detail {
					decorator = .safe
				} else {
					decorator = .unowned
				}
			} else {
				decorator = .unowned
			}
		default: break
		}

		if let decorator {
			collection = collection.map {
				var copy = $0
				copy.decorators.insert(decorator)
				return copy
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
							copy.effects.append(.async)
						}
						if case .keyword(.reasync) = accessor.effectSpecifiers?.asyncSpecifier?.tokenKind {
							copy.effects.append(.reasync)
						}
						if case .keyword(.throws) = accessor.effectSpecifiers?.throwsClause?.throwsSpecifier.tokenKind {
							let errorType: String? = {
								guard let type = accessor.effectSpecifiers?.throwsClause?.type else {
									return nil
								}
								return ParseAnyType<TypeNameTracker>(node: type).run()
							}()
							copy.effects.append(.throws(errorType: errorType))
						}
						if case .keyword(.rethrows) = accessor.effectSpecifiers?.throwsClause?.throwsSpecifier.tokenKind {
							copy.effects.append(.rethrows)
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
