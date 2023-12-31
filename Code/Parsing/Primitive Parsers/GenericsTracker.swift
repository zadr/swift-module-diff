import Foundation
import SwiftSyntax

struct GenericsTracker {
	let parametersNode: GenericParameterClauseSyntax?
	let requirementsNode: GenericWhereClauseSyntax?

	init(parametersNode: GenericParameterClauseSyntax? = nil, requirementsNode: GenericWhereClauseSyntax? = nil) {
		self.parametersNode = parametersNode
		self.requirementsNode = requirementsNode
	}

	func run() -> (parameters: [Parameter], constraints: [Parameter]) {
		var parameters = [Parameter]()
		var constraints = [Parameter]()

		for genericParameter in parametersNode?.parameters ?? [] {
			var parameter = Parameter()
			if case .identifier(let name) = genericParameter.name.tokenKind {
				parameter.name = name
			}
			if let inherited = genericParameter.inheritedType {
				parameter.type = ParseAnyType<TypeNameTracker>(node: inherited).run()
			}
			parameters.append(parameter)
		}

		for constraint in requirementsNode?.requirements ?? [] {
			var parameter = Parameter()
			if let sameType = constraint.requirement.as(SameTypeRequirementSyntax.self) {
				parameter.name = ParseAnyType<TypeNameTracker>(node: sameType.leftType).run()

				if case .binaryOperator = sameType.equal.tokenKind {
					parameter.separator = .doubleEqual
				}

				parameter.type = ParseAnyType<TypeNameTracker>(node: sameType.rightType).run()
			} else if let conformance = constraint.requirement.as(ConformanceRequirementSyntax.self) {
				parameter.name = ParseAnyType<TypeNameTracker>(node: conformance.leftType).run()

				if case .colon = conformance.colon.tokenKind {
					parameter.separator = .colon
				}

				parameter.type = ParseAnyType<TypeNameTracker>(node: conformance.rightType).run()
			}

			constraints.append(parameter)
		}

		return (parameters: parameters, constraints: constraints)
	}
}
