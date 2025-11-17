import Foundation
import SwiftSyntax

class SubscriptTracker: SyntaxVisitor, AnyTypeParser {
	var value = Member()

	required init() {
		value.kind = .subscript
		super.init(viewMode: .sourceAccurate)
	}

	override func visit(_ node: AccessorDeclSyntax) -> SyntaxVisitorContinueKind {
		switch node.modifier?.name.tokenKind ?? .keyword(.none) {
		case .keyword(.nonmutating):
			value.accessors.append(.nonmutating)
		case .keyword(.mutating):
			value.accessors.append(.mutating)
		default: break;
		}

		switch node.accessorSpecifier.tokenKind {
		case .keyword(.set):
			value.accessors.append(.set)
		case .keyword(.get):
			value.accessors.append(.get)

			if case .keyword(.async) = node.effectSpecifiers?.asyncSpecifier?.tokenKind {
				value.effects.append(.async)
			}
			if case .keyword(.reasync) = node.effectSpecifiers?.asyncSpecifier?.tokenKind {
				value.effects.append(.reasync)
			}
			if case .keyword(.throws) = node.effectSpecifiers?.throwsClause?.throwsSpecifier.tokenKind {
				let errorType: String? = {
					guard let type = node.effectSpecifiers?.throwsClause?.type else {
						return nil
					}
					return ParseAnyType<TypeNameTracker>(node: type).run()
				}()
				value.effects.append(.throws(errorType: errorType))
			}
			if case .keyword(.rethrows) = node.effectSpecifiers?.throwsClause?.throwsSpecifier.tokenKind {
				value.effects.append(.rethrows)
			}
		default: break
		}

		return super.visit(node)
	}

	override func visit(_ node: SubscriptDeclSyntax) -> SyntaxVisitorContinueKind {
		let generics = GenericsTracker(parametersNode: node.genericParameterClause, requirementsNode: node.genericWhereClause).run()
		value.generics += generics.parameters
		value.genericConstraints += generics.constraints

		value.attributes += node.attributes.map { ParseAnyType<AttributeTracker>(node: $0).run() }

		for modifier in node.modifiers {
			switch modifier.name.tokenKind {
			case .keyword(.static): value.decorators.insert(.static)
			case .keyword(.open): value.decorators.insert(.open)
			case .keyword(.package): value.decorators.insert(.package)
			case .keyword(.final): value.decorators.insert(.final)
			case .keyword(.nonmutating): value.decorators.insert(.nonmutating)
			case .keyword(.optional): value.decorators.insert(.optional)
			case .keyword(.dynamic): value.decorators.insert(.dynamic)
			default: break
			}

			if modifier.name.text == "__consuming" {
				value.decorators.insert(.__consuming)
			}
		}

		return super.visit(node)
	}

	override func visit(_ node: FunctionParameterSyntax) -> SyntaxVisitorContinueKind {
		var parameter = Parameter()

		if node.firstName.text == "isolated", let secondName = node.secondName {
			parameter.decorators.insert(.isolated)
			parameter.name = secondName.text
		} else {
			parameter.name = node.firstName.text + (node.secondName != nil ? " " + node.secondName!.text : "")
		}

		parameter.type = ParseAnyType<TypeNameTracker>(node: node.type).run()

		if let attributedType = node.type.as(AttributedTypeSyntax.self),
		   let specifier = attributedType.specifier {
			switch specifier.tokenKind {
			case .keyword(.inout): parameter.decorators.insert(.inout)
			case .keyword(.borrowing): parameter.decorators.insert(.borrowing)
			case .keyword(.consuming): parameter.decorators.insert(.consuming)
			default:
				switch specifier.text {
				case "__owned": parameter.decorators.insert(.__owned)
				case "__shared": parameter.decorators.insert(.__shared)
				default: break
				}
			}
		}

		if let attributes = node.type.as(AttributedTypeSyntax.self)?.attributes {
			parameter.attributes += attributes.map { ParseAnyType<AttributeTracker>(node: $0 ).run() }
		}

		if node.ellipsis != nil {
			parameter.suffix = "..."
		}

		if let defaultValue = node.defaultValue {
			parameter.defaultValue = ParseAnyType<DefaultValueTracker>(node: defaultValue).run()
		}

		value.parameters.append(parameter)
		return super.visit(node)
	}

	override func visit(_ node: ReturnClauseSyntax) -> SyntaxVisitorContinueKind {
		value.returnType = ParseAnyType<TypeNameTracker>(node: node).run()
		return super.visit(node)
	}
}
