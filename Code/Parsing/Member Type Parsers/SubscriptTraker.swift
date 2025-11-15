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
			if case .keyword(.throws) = node.effectSpecifiers?.throwsClause?.throwsSpecifier.tokenKind {
				value.effects.append(.throws)
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

		let pairs: [Keyword: Member.Decorator] = [
			.static: .static,
			.open: .open,
			.final: .final,
			.nonmutating: .nonmutating,
			.optional: .optional,
			.dynamic: .dynamic
		]

		for (keyword, decorator) in pairs {
			for modifier in node.modifiers {
				if ParseDecl<DeclTracker>(node: modifier).run(keyword: keyword) {
					value.decorators.insert(decorator)
				}
			}
		}

		return super.visit(node)
	}

	override func visit(_ node: FunctionParameterSyntax) -> SyntaxVisitorContinueKind {
		var parameter = Parameter()

		// Check if firstName is "isolated" - if so, it's a decorator, not part of the name
		if node.firstName.text == "isolated", let secondName = node.secondName {
			parameter.decorators.insert(.isolated)
			parameter.name = secondName.text
		} else {
			parameter.name = node.firstName.text + (node.secondName != nil ? " " + node.secondName!.text : "")
		}

		parameter.type = ParseAnyType<TypeNameTracker>(node: node.type).run()

		let pairs: [Keyword: Parameter.Decorator] = [
			.inout: .inout,
			.borrowing: .borrowing,
			.consuming: .consuming,
		]

		for (keyword, decorator) in pairs {
			if ParseDecl<AttributedTypeTracker>(node: node.type).run(keyword: keyword) {
				parameter.decorators.insert(decorator)
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
