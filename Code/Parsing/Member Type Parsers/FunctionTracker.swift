import Foundation
import SwiftSyntax

class FunctionTracker: SyntaxVisitor, AnyTypeParser {
	var value = Member()

	required init() {
		value.kind = .func
		super.init(viewMode: .sourceAccurate)
	}

	override func visit(_ node: DeclModifierSyntax) -> SyntaxVisitorContinueKind {
		let pairs: [Keyword: Member.Decorator] = [
			.static: .static,
			.open: .open,
			.final: .final,
			.mutating: .mutating,
			.nonmutating: .nonmutating,
			.optional: .optional,
			.dynamic: .dynamic
		]

		for (keyword, decorator) in pairs {
			if ParseDecl<DeclTracker>(node: node).run(keyword: keyword) {
				value.decorators.insert(decorator)
			}
		}
		return super.visit(node)
	}

	override func visit(_ node: FunctionDeclSyntax) -> SyntaxVisitorContinueKind {
		if case .binaryOperator(let token) = node.name.tokenKind {
			value.name = token
		} else if case .identifier(let token) = node.name.tokenKind {
			value.name = token
		} else {
			fatalError("unable to identify func name from decl")
		}

		let generics = GenericsTracker(parametersNode: node.genericParameterClause, requirementsNode: node.genericWhereClause).run()
		value.generics += generics.parameters
		value.genericConstraints += generics.constraints

		value.attributes += node.attributes.map { ParseAnyType<AttributeTracker>(node: $0).run() }

		if case .keyword(.async) = node.signature.effectSpecifiers?.asyncSpecifier?.tokenKind {
			value.effects.append(.async)
		}
		if case .keyword(.rethrows) = node.signature.effectSpecifiers?.throwsSpecifier?.tokenKind {
			value.effects.append(.rethrows)
		}
		if case .keyword(.throws) = node.signature.effectSpecifiers?.throwsSpecifier?.tokenKind {
			value.effects.append(.throws)
		}

		return super.visit(node)
	}

	override func visit(_ node: FunctionParameterSyntax) -> SyntaxVisitorContinueKind {
		var parameter = Parameter()
		parameter.name = node.firstName.text + (node.secondName != nil ? " " + node.secondName!.text : "")
		parameter.type = ParseAnyType<TypeNameTracker>(node: node.type).run()

		if node.ellipsis != nil {
			parameter.type += "..."
		}

		let pairs: [Keyword: Parameter.Decorator] = [
			.inout: .inout,
			.borrowing: .borrowing,
			.consuming: .consuming,
			.any: .any,
			.some: .some,
		]

		for (keyword, decorator) in pairs {
			if ParseDecl<AttributedTypeTracker>(node: node.type).run(keyword: keyword) {
				parameter.decorators.insert(decorator)
			}
		}

		if let attributes = node.type.as(AttributedTypeSyntax.self)?.attributes {
			parameter.attributes += attributes.map { ParseAnyType<AttributeTracker>(node: $0 ).run() }
		}

		value.parameters.append(parameter)
		return .skipChildren
	}

	override func visit(_ node: ReturnClauseSyntax) -> SyntaxVisitorContinueKind {
		value.returnType = ParseAnyType<TypeNameTracker>(node: node).run()
		return super.visit(node)
	}
}
