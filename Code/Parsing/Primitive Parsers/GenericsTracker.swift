import Foundation
import SwiftSyntax

struct GenericsTracker {
	let parametersNode: GenericParameterClauseSyntax?
	let requirementsNode: GenericWhereClauseSyntax?

	init(parametersNode: GenericParameterClauseSyntax? = nil, requirementsNode: GenericWhereClauseSyntax? = nil) {
		self.parametersNode = parametersNode
		self.requirementsNode = requirementsNode
	}

	func run() -> (parameters: [String], constraints: [Parameter]) {
		var parameters = [String]()
		var constraints = [Parameter]()

		for parameter in parametersNode?.parameters ?? [] {
			if case .identifier(let name) = parameter.name.tokenKind {
				parameters.append(name)
			}
		}

		for constraint in requirementsNode?.requirements ?? [] {
			var parameter = Parameter()
			if let sameType = constraint.requirement.as(SameTypeRequirementSyntax.self) {
				if let left = sameType.leftType.as(IdentifierTypeSyntax.self)?.name {
					if case .identifier(let name) = left.tokenKind {
						parameter.name = name
					}
				}

				if case .binaryOperator(let text) = sameType.equal.tokenKind {
					parameter.separator = .init(rawValue: text)!
				}

				parameter.type = ParseAnyType<TypeNameTracker>(node: sameType.rightType).run()
			} else if let conformance = constraint.requirement.as(ConformanceRequirementSyntax.self) {
				if let left = conformance.leftType.as(IdentifierTypeSyntax.self)?.name {
					if case .identifier(let name) = left.tokenKind {
						parameter.name = name
					}
				}

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
